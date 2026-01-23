{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkIf
    types
    filterAttrs
    mapAttrs
    optionalAttrs
    ;

  opencodeCfg = config.programs.opencode;
  cfg = config.programs.opencode.mcps;

  # ----------------------
  # Tools Management
  # ----------------------
  baseTools = import ../../../../tools.nix {
    inherit pkgs lib;
    inputs = { };
  };

  # ----------------------
  # Preset Management
  # ----------------------
  mcpServerOptionsType = import ../../../lib/mcp-server-options.nix lib;
  presetDefinitions = import ../../../../presets.nix {
    inherit config lib pkgs;
    tools = baseTools;
  };

  presetOptionTypes = mapAttrs (
    name: preset:
    mkOption {
      type = lib.types.submodule preset;
      default = { };
      description = lib.mdDoc (preset.meta.description or "MCP preset for ${name}");
    }
  ) presetDefinitions;

  # ----------------------
  # Server Configuration Management
  # ----------------------
  # Transform presets to OpenCode format (different from Claude format)
  enabledPresetServers =
    let
      enabledPresets = filterAttrs (name: preset: name != "servers" && (preset.enable or false)) cfg;
    in
    mapAttrs (_name: preset: {
      type = "local";
      enabled = true;
      command = [ preset.mcpServer.command ] ++ (preset.mcpServer.args or [ ]);
      environment = preset.mcpServer.env or { };
    }) enabledPresets;

  # Custom servers (non-preset) - already in OpenCode format
  customServers = cfg.servers or { };

  # All MCP servers combined
  allMcpServers = enabledPresetServers // customServers;
in
{
  options.programs.opencode = {
    mcps = mkOption {
      type = types.submodule {
        imports = [
          (_: {
            options = presetOptionTypes // {
              servers = mkOption {
                type = types.attrsOf (
                  types.submodule {
                    options = {
                      type = mkOption {
                        type = types.enum [
                          "local"
                          "remote"
                        ];
                        default = "local";
                        description = lib.mdDoc "MCP server type";
                      };
                      enabled = mkOption {
                        type = types.bool;
                        default = true;
                        description = lib.mdDoc "Whether the MCP server is enabled";
                      };
                      command = mkOption {
                        type = types.listOf types.str;
                        default = [ ];
                        description = lib.mdDoc "Command and arguments to run the MCP server";
                      };
                      url = mkOption {
                        type = types.str;
                        default = "";
                        description = lib.mdDoc "URL for remote MCP servers";
                      };
                      environment = mkOption {
                        type = types.attrsOf types.str;
                        default = { };
                        description = lib.mdDoc "Environment variables for the MCP server";
                      };
                      headers = mkOption {
                        type = types.attrsOf types.str;
                        default = { };
                        description = lib.mdDoc "HTTP headers for remote MCP servers";
                      };
                    };
                  }
                );
                default = { };
                description = lib.mdDoc "Custom MCP server configurations in OpenCode format";
              };
            };
          })
        ];
      };
      default = { };
      description = lib.mdDoc "MCP server configurations for OpenCode";
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = { };
      description = lib.mdDoc "Extra configuration to merge into opencode settings (e.g., providers)";
    };
  };

  config = mkIf opencodeCfg.enable {
    # Integrate with Home Manager's built-in programs.opencode module
    # by setting settings.mcp instead of writing xdg.configFile directly.
    # This allows proper merging with other settings (e.g., theme from stylix).
    programs.opencode.settings = lib.mkMerge [
      (optionalAttrs (allMcpServers != { }) { mcp = allMcpServers; })
      opencodeCfg.extraConfig
    ];
  };
}
