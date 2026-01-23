# =============================================================================
# Basic Home Manager MCP Setup
#
# Simple flake template showing basic MCP integration with Home Manager
# Includes essential token-efficient MCPs per todo.md guidance
#
# Usage: nix flake init -t mcps.nix#basic-home-manager
# =============================================================================
{
  description = "Basic Home Manager MCP Setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    mcps.url = "github:your-org/mcps.nix";
  };

  outputs = { nixpkgs, home-manager, mcps, ... }: {
    homeManagerConfigurations."your-username" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        # Import Home Manager module from mcps.nix
        mcps.homeManagerModules.claude
        {
          # Home Manager base configuration
          home.stateVersion = "25.11";
          home.username = "your-username";
          home.homeDirectory = "/home/your-username";

          # Enable Claude Code with MCPs
          programs.claude-code = {
            enable = true;
            mcps = {
              # Token-efficient MCPs (per todo.md)
              nixos.enable = true;          # NixOS option querying
              config-normalizer.enable = true; # Config file conversion to XML
              flake-analyst.enable = true;   # flake.lock parsing
              code-intel.enable = true;      # Tree-sitter code analysis
              ast-grep.enable = true;        # Structural code search
              
              # Additional useful MCPs
              filesystem.enable = true;        # File operations (sandboxed)
              git.enable = true;             # Git operations
              fetch.enable = true;           # Web content fetching
              time.enable = true;            # Timezone awareness
            };
          };
        }
      ];
    };
  };
}