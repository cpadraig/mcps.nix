# =============================================================================
# Comprehensive Home Manager MCP Setup
#
# Full-featured flake template showing complete MCP integration with Home Manager
# Includes all available MCPs with configuration examples and security patterns
#
# Usage: nix flake init -t mcps.nix#comprehensive-home-manager
# =============================================================================
{
  description = "Comprehensive Home Manager MCP Setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    mcps.url = "github:your-org/mcps.nix";
    
    # For development environment
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, mcps, devenv, ... }: {
    # Development environment for managing this flake
    devShells.x86_64-linux.default = devenv.lib.mkShell {
      imports = [ mcps.devenvModules.claude ];
      
      packages = with nixpkgs; [
        git
        nixfmt-rfc-style
      ];

      claude.code = {
        enable = true;
        mcps = {
          # Essential MCPs for token efficiency
          nixos.enable = true;
          config-normalizer.enable = true;
          flake-analyst.enable = true;
          code-intel = {
            enable = true;
            languages = ["python" "nix" "java"];
          };
          ast-grep.enable = true;
          
          # Development tools
          git.enable = true;
          fetch.enable = true;
          filesystem = {
            enable = true;
            allowedPaths = ["/home/your-username/Projects"];
          };
          
          # External service integrations (with examples)
          github = {
            enable = true;
            tokenFilepath = "/var/run/agenix/github.token";
            toolsets = ["context" "repos" "pull_requests" "users"];
          };
          grafana = {
            enable = true;
            baseURL = "https://your-grafana.company.com";
            apiKeyFilepath = "/var/run/agenix/grafana.key";
            toolsets = ["prometheus" "search" "datasource"];
          };
          asana = {
            enable = true;
            tokenFilepath = "/var/run/agenix/asana.token";
          };
          
          # LSP integrations for multiple languages
          lsp-nix = {
            enable = true;
            workspace = "/home/your-username/Projects";
          };
          lsp-python = {
            enable = true;
            workspace = "/home/your-username/Projects";
          };
          lsp-typescript = {
            enable = true;
            workspace = "/home/your-username/Projects";
          };
          lsp-rust = {
            enable = true;
            workspace = "/home/your-username/Projects";
          };
          
          # Time and planning tools
          time = {
            enable = true;
            localTimezone = "America/New_York";
          };
          sequential-thinking.enable = true;
        };
      };
    };

    # Production Home Manager configuration
    homeManagerConfigurations."your-username" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        mcps.homeManagerModules.claude
        
        # Configuration for different environments
        {
          home.stateVersion = "25.11";
          home.username = "your-username";
          home.homeDirectory = "/home/your-username";

          programs.claude-code = {
            enable = true;
            
            # Production MCP configuration (more conservative)
            mcps = {
              # Core token-efficient MCPs
              nixos.enable = true;
              config-normalizer.enable = true;
              flake-analyst.enable = true;
              code-intel.enable = true;
              ast-grep.enable = true;
              
              # Essential development tools
              git.enable = true;
              fetch.enable = true;
              filesystem = {
                enable = true;
                allowedPaths = [
                  "/home/your-username"
                  "/home/your-username/Projects"
                ];
              };
              
              # LSP for primary development language
              lsp-nix = {
                enable = true;
                workspace = "/home/your-username/Projects";
              };
              
              # Time awareness
              time = {
                enable = true;
                localTimezone = "America/New_York";
              };
              
              # External integrations (configured per environment)
              github = {
                enable = true;
                tokenFilepath = "$HOME/.config/claude/github.token";
                toolsets = ["context" "repos" "pull_requests"];
              };
            };
          };
        }
      ];
    };
  };
}