# Tests for new MCP presets: config-normalizer, flake-analyst, code-intel
# These tests verify the presets work correctly via the home-manager module
{
  inputs,
  pkgs,
  system,
  ...
}: let


  # Test configuration for config-normalizer
  configNormalizerResult = inputs.home-manager-unstable.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        inputs.self.overlays.default
      ];
    };
    modules = [
      inputs.self.homeManagerModules.claude
      {
        home.stateVersion = "25.11";
        home.username = "testuser";
        home.homeDirectory = "/test";
        programs.claude-code = {
          enable = true;
          mcps.config-normalizer.enable = true;
        };
      }
    ];
  };

  # Test configuration for flake-analyst
  flakeAnalystResult = inputs.home-manager-unstable.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        inputs.self.overlays.default
      ];
    };
    modules = [
      inputs.self.homeManagerModules.claude
      {
        home.stateVersion = "25.11";
        home.username = "testuser";
        home.homeDirectory = "/test";
        programs.claude-code = {
          enable = true;
          mcps.flake-analyst.enable = true;
        };
      }
    ];
  };

  # Test configuration for code-intel
  codeIntelResult = inputs.home-manager-unstable.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        inputs.self.overlays.default
      ];
    };
    modules = [
      inputs.self.homeManagerModules.claude
      {
        home.stateVersion = "25.11";
        home.username = "testuser";
        home.homeDirectory = "/test";
        programs.claude-code = {
          enable = true;
          mcps.code-intel.enable = true;
        };
      }
    ];
  };

  # Test configuration for code-intel with custom languages
  codeIntelCustomResult = inputs.home-manager-unstable.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        inputs.self.overlays.default
      ];
    };
    modules = [
      inputs.self.homeManagerModules.claude
      {
        home.stateVersion = "25.11";
        home.username = "testuser";
        home.homeDirectory = "/test";
        programs.claude-code = {
          enable = true;
          mcps.code-intel = {
            enable = true;
            languages = ["python" "nix"];
          };
        };
      }
    ];
  };
in {
  tests = [


    # ========================================
    # Config Normalizer Preset Tests
    # ========================================
    {
      name = "config-normalizer command is configured";
      type = "script";
      script = ''
        ${(inputs.nixtest.lib {inherit pkgs;}).helpers.scriptHelpers}
        MCP_CONFIG="$(cat ${configNormalizerResult.config.programs.claude-code.finalPackage}/bin/claude | ${pkgs.gnugrep}/bin/grep mcp-config | ${pkgs.gawk}/bin/awk '{ print $6 }')"
        CMD_ACTUAL="$(${pkgs.jq}/bin/jq -r '.mcpServers."config-normalizer".command' $MCP_CONFIG)"
        if [[ -z "$CMD_ACTUAL" || "$CMD_ACTUAL" == "null" ]]; then
           echo "config-normalizer mcp server command not configured"
           exit 1
        fi
      '';
    }
    {
      name = "config-normalizer env is empty";
      type = "unit";
      expected = {};
      actual = configNormalizerResult.config.programs.claude-code.mcpServers.config-normalizer.env;
    }

    # ========================================
    # Flake Analyst Preset Tests
    # ========================================
    {
      name = "flake-analyst command is configured";
      type = "script";
      script = ''
        ${(inputs.nixtest.lib {inherit pkgs;}).helpers.scriptHelpers}
        MCP_CONFIG="$(cat ${flakeAnalystResult.config.programs.claude-code.finalPackage}/bin/claude | ${pkgs.gnugrep}/bin/grep mcp-config | ${pkgs.gawk}/bin/awk '{ print $6 }')"
        CMD_ACTUAL="$(${pkgs.jq}/bin/jq -r '.mcpServers."flake-analyst".command' $MCP_CONFIG)"
        if [[ -z "$CMD_ACTUAL" || "$CMD_ACTUAL" == "null" ]]; then
           echo "flake-analyst mcp server command not configured"
           exit 1
        fi
      '';
    }
    {
      name = "flake-analyst env is empty";
      type = "unit";
      expected = {};
      actual = flakeAnalystResult.config.programs.claude-code.mcpServers.flake-analyst.env;
    }

    # ========================================
    # Code Intel Preset Tests
    # ========================================
    {
      name = "code-intel command is configured";
      type = "script";
      script = ''
        ${(inputs.nixtest.lib {inherit pkgs;}).helpers.scriptHelpers}
        MCP_CONFIG="$(cat ${codeIntelResult.config.programs.claude-code.finalPackage}/bin/claude | ${pkgs.gnugrep}/bin/grep mcp-config | ${pkgs.gawk}/bin/awk '{ print $6 }')"
        CMD_ACTUAL="$(${pkgs.jq}/bin/jq -r '.mcpServers."code-intel".command' $MCP_CONFIG)"
        if [[ -z "$CMD_ACTUAL" || "$CMD_ACTUAL" == "null" ]]; then
           echo "code-intel mcp server command not configured"
           exit 1
        fi
      '';
    }
    {
      name = "code-intel env is empty";
      type = "unit";
      expected = {};
      actual = codeIntelResult.config.programs.claude-code.mcpServers.code-intel.env;
    }
    {
      name = "code-intel languages default";
      type = "unit";
      expected = ["python" "nix" "java"];
      actual = codeIntelResult.config.programs.claude-code.mcps.code-intel.languages;
    }
    {
      name = "code-intel languages custom";
      type = "unit";
      expected = ["python" "nix"];
      actual = codeIntelCustomResult.config.programs.claude-code.mcps.code-intel.languages;
    }
  ];
}
