{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    filterAttrs
    mapAttrs
    ;

  cfg = config.services.opencode-server;

  # ----------------------
  # Tools Management
  # ----------------------
  baseTools = import ../../../../tools.nix {
    inherit pkgs lib;
    inputs = {};
  };

  # ----------------------
  # Preset Management
  # ----------------------
  mcpServerOptionsType = import ../../../lib/mcp-server-options.nix lib;
  presetDefinitions = import ../../../../presets.nix {
    inherit config lib pkgs;
    tools = baseTools;
  };

  presetOptionTypes =
    mapAttrs (
      name: preset:
        mkOption {
          type = lib.types.submodule preset;
          default = {};
          description = lib.mdDoc (preset.meta.description or "MCP preset for ${name}");
        }
    )
    presetDefinitions;

  # ----------------------
  # Server Configuration Management
  # ----------------------
  enabledPresetServers = let
    enabledPresets = filterAttrs (name: preset: name != "servers" && (preset.enable or false)) cfg.mcps;
  in
    mapAttrs (_name: preset: {
      type = "local";
      enabled = true;
      command = [preset.mcpServer.command] ++ (preset.mcpServer.args or []);
      environment = preset.mcpServer.env or {};
    })
    enabledPresets;

  # Custom servers (non-preset)
  customServers = cfg.mcps.servers or {};

  # All MCP servers combined
  allMcpServers = enabledPresetServers // customServers;

  # Generate OpenCode JSON config
  opencodeConfig =
    {
      "$schema" = "https://opencode.ai/config.json";
      server = {
        inherit (cfg) port hostname;
        mdns = false;
      };
    }
    // (
      if allMcpServers != {}
      then {mcp = allMcpServers;}
      else {}
    )
    // cfg.extraConfig;

  configFile = pkgs.writeText "opencode-config.json" (builtins.toJSON opencodeConfig);
in {
  options.services.opencode-server = {
    enable = mkEnableOption "OpenCode Headless AI Server";

    package = mkOption {
      type = types.package;
      description = "OpenCode package to use";
    };

    port = mkOption {
      type = types.port;
      default = 4096;
      description = "Port to run OpenCode server on";
    };

    hostname = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Hostname to bind OpenCode server to";
    };

    user = mkOption {
      type = types.str;
      default = "opencode";
      description = "User to run OpenCode server as";
    };

    group = mkOption {
      type = types.str;
      default = "opencode";
      description = "Group to run OpenCode server as";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to open the firewall port";
    };

    mcps = mkOption {
      type = types.submodule {
        options =
          presetOptionTypes
          // {
            servers = mkOption {
              type = types.attrsOf (types.submodule mcpServerOptionsType);
              default = {};
              description = lib.mdDoc "Custom MCP server configurations";
            };
          };
      };
      default = {};
      description = "MCP server configurations";
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra configuration to merge into opencode.json (e.g., Ollama provider)";
    };
  };

  config = mkIf cfg.enable {
    # Create dedicated user/group
    users.users.${cfg.user} = mkIf (cfg.user == "opencode") {
      inherit (cfg) group;
      isSystemUser = true;
      home = "/var/lib/opencode";
      createHome = true;
    };
    users.groups.${cfg.group} = mkIf (cfg.group == "opencode") {};

    # Install opencode package
    environment.systemPackages = [cfg.package];

    # Systemd service
    systemd.services.opencode-server = {
      description = "OpenCode Headless AI Server";
      after =
        ["network.target" "ollama.service"];
      wants =
        ["ollama.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = "opencode";
        WorkingDirectory = "/var/lib/opencode";
        ExecStart = "${cfg.package}/bin/opencode web --port ${toString cfg.port} --hostname ${cfg.hostname}";
        Restart = "always";
        RestartSec = "10s";

        # Hardening
        ProtectSystem = "full";
        ProtectHome = "read-only";
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        RestrictNamespaces = true;
      };

      environment = {
        HOME = "/var/lib/opencode";
        XDG_CONFIG_HOME = "/var/lib/opencode/.config";
        XDG_DATA_HOME = "/var/lib/opencode/.local/share";
        XDG_CACHE_HOME = "/var/lib/opencode/.cache";
        OPENCODE_CONFIG = configFile;
        OPENCODE_DISABLE_AUTOUPDATE = "true";
      };
    };

    # Firewall
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [cfg.port];

    # Tailscale access (if tailscale is enabled)
    networking.firewall.interfaces.${config.services.tailscale.interfaceName or ""}.allowedTCPPorts =
      mkIf (config.services.tailscale.enable or false) [cfg.port];
  };
}
