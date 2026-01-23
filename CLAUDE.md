# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a fork of [roman/mcps.nix](https://github.com/roman/mcps.nix) providing MCP (Model Context Protocol) server presets for Claude Code. This fork adds:

- **OpenCode integration** - `programs.opencode.mcps` module for Home Manager
- **NixOS module** - System-level MCP configuration
- **3 new presets**: `config-normalizer`, `flake-analyst`, `code-intel`
- **Python patching** - fastmcp 2.14.2 with MCP 1.25.0 compatibility
- **Flake templates** - Quick-start configurations

## Build/Test/Lint Commands

```bash
nix develop                      # Enter dev shell with pre-commit hooks
nix fmt                          # Format all Nix files (nixfmt-rfc-style)
nix flake check                  # Verify flake validity
```

### Running Tests (nixtest)
```bash
# Core tests
nix run gitlab:technofab/nixtest -- run .#nixtest.suites.\"home-manager/claude\"
nix run gitlab:technofab/nixtest -- run .#nixtest.suites.\"devenv/claude\"
nix run gitlab:technofab/nixtest -- run .#nixtest.suites.\"home-manager/claude-install\"

# Fork-specific tests
nix run gitlab:technofab/nixtest -- run .#nixtest.suites.\"presets/new\"
nix run gitlab:technofab/nixtest -- run .#nixtest.suites.\"nixos/opencode\"
nix run gitlab:technofab/nixtest -- run .#nixtest.suites.\"home-manager/opencode\"
nix run gitlab:technofab/nixtest -- run .#nixtest.suites.\"devenv/new-presets\"
```

### Building Packages
```bash
nix build .#mcp-servers          # All stdlib MCP servers
nix build .#config-normalizer    # Config file normalizer
nix build .#flake-analyst        # Flake.lock analyzer
nix build .#code-intel           # Tree-sitter code structure
```

## Architecture

### Key Files
| File | Purpose |
|------|---------|
| `flake.nix` | Entry point, overlay with Python patching for fastmcp 2.14.2 |
| `presets.nix` | MCP server preset definitions (20 presets) |
| `tools.nix` | Tool packaging and path resolution |
| `nix/modules/home-manager/claude/` | Native HM Claude integration |
| `nix/modules/home-manager/opencode/` | OpenCode integration (fork-only) |
| `nix/modules/nixos/` | NixOS module (fork-only) |
| `nix/packages/` | Custom MCP server packages |

### IFD Avoidance Pattern (Key Difference from Upstream)

Presets use `toolName` instead of `command` to avoid Import From Derivation during option definition:

```nix
# In presets.nix
github = {
  name = "GitHub";
  toolName = "github";  # NOT: command = tools.getToolPath "github"
  # ...
};

# In mkPresetModule (presets.nix)
config = mkIf config.enable {
  mcpServer = {
    command = tools.getToolPath toolName;  # Resolved lazily when enabled
    # ...
  };
};
```

### Python Dependency Patching

The overlay patches Python for fastmcp 2.14.2 compatibility:
- `py-key-value-shared`, `py-key-value-aio`, `pydocket` - New dependencies
- `mcp-nixos` rebuilt with patched Python

## Adding New Presets

1. Add package in `nix/packages/<name>/default.nix`
2. Add tool entry in `tools.nix`:
   ```nix
   my-tool = mkTool {
     package = pkgs.my-package;
     binary = "my-binary";
   };
   ```
3. Add preset in `presets.nix`:
   ```nix
   my-preset = {
     name = "My Preset";
     toolName = "my-tool";  # Use toolName, not command
     args = _config: [ ];
     env = _config: { };
     options = { };
   };
   ```
4. Add to overlay in `flake.nix` if custom package
5. Add tests in `tests/`
6. Run `nix fmt`

## Templates

Initialize new projects with:
```bash
nix flake init -t github:cpadraig/mcps.nix#basic-home-manager
nix flake init -t github:cpadraig/mcps.nix#comprehensive-home-manager
nix flake init -t github:cpadraig/mcps.nix#devenv-setup
nix flake init -t github:cpadraig/mcps.nix#nixos-service
```

## Code Style

See `AGENTS.md` for detailed code style guidelines including:
- Nix formatting conventions (nixfmt-rfc-style)
- Module patterns and preset definitions
- Python MCP server conventions
- Testing patterns
