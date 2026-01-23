# Tests for new MCP presets in devenv context
# Tests config-normalizer, flake-analyst, code-intel via devenv module
{
  inputs,
  pkgs,
  system,
  ...
}: let

    ];
  };

  # Test configuration for config-normalizer in devenv
  configNormalizerConfig = inputs.devenv.lib.mkConfig {
    inherit inputs;
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        inputs.self.overlays.default
      ];
    };
    modules = [
      inputs.self.devenvModules.claude
      {
        claude.code = {
          enable = true;
          mcps.config-normalizer.enable = true;
        };
      }
    ];
  };

  # Test configuration for flake-analyst in devenv
  flakeAnalystConfig = inputs.devenv.lib.mkConfig {
    inherit inputs;
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        inputs.self.overlays.default
      ];
    };
    modules = [
      inputs.self.devenvModules.claude
      {
        claude.code = {
          enable = true;
          mcps.flake-analyst.enable = true;
        };
      }
    ];
  };

  # Test configuration for code-intel in devenv
  codeIntelConfig = inputs.devenv.lib.mkConfig {
    inherit inputs;
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        inputs.self.overlays.default
      ];
    };
    modules = [
      inputs.self.devenvModules.claude
      {
        claude.code = {
          enable = true;
          mcps.code-intel = {
            enable = true;
            languages = ["python" "nix"];
          };
        };
      }
    ];
  };

  # Test configuration with all new presets enabled
  allNewPresetsConfig = inputs.devenv.lib.mkConfig {
    inherit inputs;
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        inputs.self.overlays.default
      ];
    };
    modules = [
      inputs.self.devenvModules.claude
      {
        claude.code = {
          enable = true;
          mcps = {
            config-normalizer.enable = true;
            flake-analyst.enable = true;
            code-intel.enable = true;
          };
        };
      }
    ];
  };
in {
  tests = [



    # ========================================
    # Config Normalizer Devenv Tests
    # ========================================
    {
      name = "config-normalizer command in mcp.json";
      type = "script";
      script = ''
        MCP_CONFIG="${configNormalizerConfig.files.".mcp.json".file}"
        CMD_ACTUAL="$(${pkgs.jq}/bin/jq -r '.mcpServers."config-normalizer".command' $MCP_CONFIG)"
        if [[ -z "$CMD_ACTUAL" || "$CMD_ACTUAL" == "null" ]]; then
           echo "config-normalizer command not found in .mcp.json"
           exit 1
        fi
      '';
    }
    {
      name = "config-normalizer env empty in devenv";
      type = "unit";
      expected = {};
      actual = configNormalizerConfig.claude.code.mcpServers.config-normalizer.env;
    }

    # ========================================
    # Flake Analyst Devenv Tests
    # ========================================
    {
      name = "flake-analyst command in mcp.json";
      type = "script";
      script = ''
        MCP_CONFIG="${flakeAnalystConfig.files.".mcp.json".file}"
        CMD_ACTUAL="$(${pkgs.jq}/bin/jq -r '.mcpServers."flake-analyst".command' $MCP_CONFIG)"
        if [[ -z "$CMD_ACTUAL" || "$CMD_ACTUAL" == "null" ]]; then
           echo "flake-analyst command not found in .mcp.json"
           exit 1
        fi
      '';
    }
    {
      name = "flake-analyst env empty in devenv";
      type = "unit";
      expected = {};
      actual = flakeAnalystConfig.claude.code.mcpServers.flake-analyst.env;
    }

    # ========================================
    # Code Intel Devenv Tests
    # ========================================
    {
      name = "code-intel command in mcp.json";
      type = "script";
      script = ''
        MCP_CONFIG="${codeIntelConfig.files.".mcp.json".file}"
        CMD_ACTUAL="$(${pkgs.jq}/bin/jq -r '.mcpServers."code-intel".command' $MCP_CONFIG)"
        if [[ -z "$CMD_ACTUAL" || "$CMD_ACTUAL" == "null" ]]; then
           echo "code-intel command not found in .mcp.json"
           exit 1
        fi
      '';
    }
    {
      name = "code-intel env empty in devenv";
      type = "unit";
      expected = {};
      actual = codeIntelConfig.claude.code.mcpServers.code-intel.env;
    }
    {
      name = "code-intel languages option in devenv";
      type = "unit";
      expected = ["python" "nix"];
      actual = codeIntelConfig.claude.code.mcps.code-intel.languages;
    }

    # ========================================
    # Multiple Presets Tests
    # ========================================
    {
      name = "all new presets can be enabled together";
      type = "script";
      script = ''
        MCP_CONFIG="${allNewPresetsConfig.files.".mcp.json".file}"
        

        
        # Check config-normalizer
        CONFIG_NORM="$(${pkgs.jq}/bin/jq -r '.mcpServers."config-normalizer".command' $MCP_CONFIG)"
        if [[ -z "$CONFIG_NORM" || "$CONFIG_NORM" == "null" ]]; then
           echo "config-normalizer not found when all presets enabled"
           exit 1
        fi
        
        # Check flake-analyst
        FLAKE_ANALYST="$(${pkgs.jq}/bin/jq -r '.mcpServers."flake-analyst".command' $MCP_CONFIG)"
        if [[ -z "$FLAKE_ANALYST" || "$FLAKE_ANALYST" == "null" ]]; then
           echo "flake-analyst not found when all presets enabled"
           exit 1
        fi
        
        # Check code-intel
        CODE_INTEL="$(${pkgs.jq}/bin/jq -r '.mcpServers."code-intel".command' $MCP_CONFIG)"
        if [[ -z "$CODE_INTEL" || "$CODE_INTEL" == "null" ]]; then
           echo "code-intel not found when all presets enabled"
           exit 1
        fi
        
        echo "All new presets configured successfully"
      '';
    }
  ];
}
