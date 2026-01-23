# =============================================================================
# Development Environment MCP Setup
#
# Devenv template for creating development shells with MCP integration
# Focused on development workflow optimization and token efficiency
#
# Usage: nix flake init -t mcps.nix#devenv-setup
# =============================================================================
{
  description = "Development Environment with MCPs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    mcps.url = "github:your-org/mcps.nix";
  };

  outputs = { nixpkgs, devenv, mcps, ... }: {
    # Main development environment
    devShells.x86_64-linux.default = devenv.lib.mkShell {
      imports = [ mcps.devenvModules.claude ];

      packages = with nixpkgs; [
        # Core development tools
        git
        gh  # GitHub CLI
        nixfmt-rfc-style
        nil  # Nix LSP
        nodejs
        python3
        cargo
        rustc
        
        # Project management tools
        just
        pre-commit
        
        # Debugging and profiling
        strace
        lsof
      ];

      # Environment variables for development
      env = {
        GIT_EDITOR = "vim";
        NIX_CONFIG = "~/.config/nix/nix.conf";
      };

      # Claude Code with development-focused MCPs
      claude.code = {
        enable = true;
        forceOverride = true;
        supportEmacs = true;
        
        mcps = {
          # Essential token-efficient MCPs
          nixos.enable = true;          # NixOS/package discovery
          config-normalizer.enable = true; # Config file analysis
          flake-analyst.enable = true;   # Dependency analysis
          code-intel = {
            enable = true;
            languages = ["python" "nix" "java" "rust" "javascript"];
          };
          ast-grep.enable = true;        # Code search/replace
          
          # Development workflow tools
          git.enable = true;             # Git operations via MCP
          fetch.enable = true;           # Documentation fetching
          filesystem = {
            enable = true;
            allowedPaths = ["${builtins.toString ./.}/.."]; # Project root
          };
          
          # Language-specific LSPs
          lsp-nix = {
            enable = true;
            workspace = "${builtins.toString ./.}";
          };
          lsp-python.enable = true;
          lsp-rust = {
            enable = true;
            workspace = "${builtins.toString ./.}";
          };
          lsp-typescript.enable = true;
          
          # Planning and analysis
          time = {
            enable = true;
            localTimezone = "America/New_York";
          };
          sequential-thinking.enable = true;
          
          # External integrations (development accounts)
          github = {
            enable = true;
            tokenFilepath = "${builtins.toString ./.}/.github.token";
            toolsets = ["context" "repos" "pull_requests" "issues"];
          };
        };
      };

      # Git hooks for code quality
      git-hooks.hooks = {
        nixfmt-rfc-style.enable = true;
        pre-commit.enable = true;
      };

      # Scripts for common development tasks
      scripts = {
        build-dev = {
          description = "Build the project in development mode";
          exec = ''
            echo "Building project..."
            nix build .# --no-link
          '';
        };
        
        test-mcps = {
          description = "Test MCP configuration";
          exec = ''
            echo "Testing MCP configuration..."
            claude --version
            echo "MCPs configured:"
            ls ~/.claude/mcp-servers/ || echo "No MCP servers found"
          '';
        };
        
        clean-derivations = {
          description = "Clean old Nix derivations";
          exec = ''
            echo "Cleaning Nix store..."
            nix-collect-garbage -d
          '';
        };
      };

      # Enter development environment with helpful information
      enterShell = ''
        echo "🚀 Development Environment Ready!"
        echo "📁 Project: $(basename "$PWD")"
        echo "🔧 Available commands:"
        echo "  build-dev    - Build the project"
        echo "  test-mcps    - Test MCP configuration"
        echo "  clean-derivations - Clean Nix store"
        echo "🤖 Claude Code MCPs:"
        echo "  - nixos: NixOS/package discovery"
        echo "  - config-normalizer: Config file analysis"
        echo "  - flake-analyst: Dependency analysis"
        echo "  - code-intel: Multi-language code analysis"
        echo "  - ast-grep: Structural code search"
        echo "  - git: Enhanced Git operations"
        echo "  - LSP servers for Nix, Python, Rust, TypeScript"
      '';
    };

    # Additional specialized development environments
    
    # Minimal environment for quick testing
    devShells.x86_64-linux.minimal = devenv.lib.mkShell {
      imports = [ mcps.devenvModules.claude ];
      
      packages = with nixpkgs; [git nixfmt-rfc-style];
      
      claude.code = {
        enable = true;
        mcps = {
          # Minimal essential MCPs
          nixos.enable = true;
          code-intel.enable = true;
          git.enable = true;
        };
      };
    };

    # Frontend development environment
    devShells.x86_64-linux.frontend = devenv.lib.mkShell {
      imports = [ mcps.devenvModules.claude ];
      
      packages = with nixpkgs; [
        git
        nodejs
        npm
        typescript
        nixfmt-rfc-style
      ];
      
      claude.code = {
        enable = true;
        mcps = {
          nixos.enable = true;
          code-intel.enable = true;
          ast-grep.enable = true;
          lsp-typescript.enable = true;
          git.enable = true;
          fetch.enable = true;
        };
      };
      
      enterShell = ''
        echo "⚛️  Frontend Development Environment"
        echo "Node.js: $(node --version)"
        echo "TypeScript: $(tsc --version)"
        echo "Claude Code MCPs: TypeScript, AST search, Git, Fetch"
      '';
    };

    # Backend development environment
    devShells.x86_64-linux.backend = devenv.lib.mkShell {
      imports = [ mcps.devenvModules.claude ];
      
      packages = with nixpkgs; [
        git
        python3
        python3Packages.pip
        nixfmt-rfc-style
      ];
      
      claude.code = {
        enable = true;
        mcps = {
          nixos.enable = true;
          code-intel.enable = true;
          lsp-python.enable = true;
          git.enable = true;
          fetch.enable = true;
          time.enable = true;
        };
      };
      
      enterShell = ''
        echo "🐍 Backend Development Environment"
        echo "Python: $(python --version)"
        echo "Claude Code MCPs: Python, NixOS, Git, Fetch, Time"
      '';
    };
  };
}