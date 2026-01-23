# Tests for Home Manager opencode module
# These tests verify the module structure and integration with HM's programs.opencode
{
  inputs,
  pkgs,
  system,
  ...
}: let
  # Read the module source to verify structure
  moduleSource = builtins.readFile ../nix/modules/home-manager/opencode/default.nix;

  # Check that the module is a function (proper Home Manager module format)
  moduleIsFunction = builtins.isFunction (import ../nix/modules/home-manager/opencode);

  # Verify the flake exports the module
  homeManagerModulesExist = inputs.self ? homeManagerModules;
  opencodeModuleExists = inputs.self.homeManagerModules ? opencode;

  # Helper to evaluate Home Manager configuration with our module
  evalConfig = extraConfig:
    inputs.home-manager-unstable.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          inputs.self.overlays.default
        ];
      };
      modules = [
        inputs.self.homeManagerModules.opencode
        {
          home.stateVersion = "25.11";
          home.username = "jdoe";
          home.homeDirectory = "/test";
          programs.opencode.enable = true;
        }
        extraConfig
      ];
    };

  # Basic config without presets
  basicResult = evalConfig {};

  # Config with custom server (no store paths)
  customServerResult = evalConfig {
    programs.opencode.mcps.servers.custom-server = {
      type = "local";
      enabled = true;
      command = ["/usr/bin/custom-mcp"];
    };
  };

  # Config with remote server
  remoteServerResult = evalConfig {
    programs.opencode.mcps.servers.context7 = {
      type = "remote";
      url = "https://mcp.context7.com/mcp";
      enabled = true;
    };
  };

  # Config with extraConfig
  extraConfigResult = evalConfig {
    programs.opencode.extraConfig = {
      autoupdate = false;
    };
  };

  # Config with preset enabled
  gitResult = evalConfig {
    programs.opencode.mcps.git.enable = true;
  };

  # Get settings for tests (now we check programs.opencode.settings instead of xdg.configFile)
  basicSettings = basicResult.config.programs.opencode.settings;
  customServerSettings = customServerResult.config.programs.opencode.settings;
  remoteServerSettings = remoteServerResult.config.programs.opencode.settings;
  extraConfigSettings = extraConfigResult.config.programs.opencode.settings;
  gitSettings = gitResult.config.programs.opencode.settings;

  # Check that settings has mcp attribute for servers
  hasGitMcp = gitSettings ? mcp && gitSettings.mcp ? git;
in {
  tests = [
    # ========================================
    # Module Export Tests
    # ========================================
    {
      name = "flake exports homeManagerModules";
      type = "unit";
      expected = true;
      actual = homeManagerModulesExist;
    }
    {
      name = "homeManagerModules contains opencode";
      type = "unit";
      expected = true;
      actual = opencodeModuleExists;
    }
    {
      name = "opencode module is a function";
      type = "unit";
      expected = true;
      actual = moduleIsFunction;
    }

    # ========================================
    # Module Source Structure Tests
    # ========================================
    {
      name = "module declares programs.opencode option";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "programs.opencode" "$MODULE_SRC"; then
          echo "Module does not declare programs.opencode"
          exit 1
        fi
      '';
    }
    {
      name = "module declares mcps option";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "mcps = mkOption" "$MODULE_SRC"; then
          echo "Module does not declare mcps option"
          exit 1
        fi
      '';
    }
    {
      name = "module declares extraConfig option";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "extraConfig = mkOption" "$MODULE_SRC"; then
          echo "Module does not declare extraConfig option"
          exit 1
        fi
      '';
    }
    {
      name = "module sets programs.opencode.settings";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "programs.opencode.settings" "$MODULE_SRC"; then
          echo "Module does not set programs.opencode.settings"
          exit 1
        fi
      '';
    }

    # ========================================
    # Custom Server Tests (no store paths)
    # ========================================
    {
      name = "custom server exists in settings.mcp";
      type = "unit";
      expected = true;
      actual = customServerSettings ? mcp && customServerSettings.mcp ? custom-server;
    }
    {
      name = "custom server command";
      type = "unit";
      expected = ["/usr/bin/custom-mcp"];
      actual = customServerSettings.mcp.custom-server.command;
    }
    {
      name = "custom server type";
      type = "unit";
      expected = "local";
      actual = customServerSettings.mcp.custom-server.type;
    }
    {
      name = "custom server enabled";
      type = "unit";
      expected = true;
      actual = customServerSettings.mcp.custom-server.enabled;
    }

    # ========================================
    # Remote Server Tests
    # ========================================
    {
      name = "remote server exists in settings.mcp";
      type = "unit";
      expected = true;
      actual = remoteServerSettings ? mcp && remoteServerSettings.mcp ? context7;
    }
    {
      name = "remote server type";
      type = "unit";
      expected = "remote";
      actual = remoteServerSettings.mcp.context7.type;
    }
    {
      name = "remote server url";
      type = "unit";
      expected = "https://mcp.context7.com/mcp";
      actual = remoteServerSettings.mcp.context7.url;
    }

    # ========================================
    # Extra Config Tests
    # ========================================
    {
      name = "extraConfig merges into settings";
      type = "unit";
      expected = true;
      actual = extraConfigSettings ? autoupdate;
    }
    {
      name = "extraConfig value is correct";
      type = "unit";
      expected = false;
      actual = extraConfigSettings.autoupdate;
    }

    # ========================================
    # Preset Tests
    # ========================================
    {
      name = "git preset creates mcp entry";
      type = "unit";
      expected = true;
      actual = hasGitMcp;
    }
    {
      name = "git preset has correct type";
      type = "unit";
      expected = "local";
      actual = gitSettings.mcp.git.type;
    }
    {
      name = "git preset is enabled";
      type = "unit";
      expected = true;
      actual = gitSettings.mcp.git.enabled;
    }
  ];
}
