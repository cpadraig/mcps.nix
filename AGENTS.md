# AGENTS.md - Guidelines for AI Coding Agents

This document provides instructions for AI agents working on the mcps.nix codebase,
a Nix flake providing MCP (Model Context Protocol) server presets for Claude Code.

## Project Overview

This project provides reusable MCP server configurations (presets) that integrate with:
- **devenv**: via `claude.code.mcps` configuration
- **home-manager**: via `programs.claude-code.mcps` configuration

Key files:
- `flake.nix` - Main flake definition with overlays, modules, and test suites
- `presets.nix` - MCP server preset definitions (asana, github, grafana, etc.)
- `tools.nix` - Tool packaging and path resolution utilities
- `nix/modules/` - Module implementations for devenv and home-manager
- `nix/packages/` - Custom package definitions for MCP servers
- `nix/lib/` - Shared library functions (credential wrapping, option types)
- `tests/` - Test files using nixtest framework

## Build/Lint/Test Commands

### Development Environment
```bash
nix develop                    # Enter dev shell with pre-commit hooks
```

### Formatting
```bash
nix fmt                        # Format all Nix files (nixfmt-rfc-style)
```

### Building Packages
```bash
nix build .#<package>          # Build a specific package
nix build .#mcp-servers        # Build all MCP servers bundle
nix build .#config-normalizer  # Build config-normalizer MCP server
nix build .#code-intel         # Build code-intel MCP server
nix build .#all                # Build all packages
```

### Running Tests
Tests use the nixtest framework. Test suites are defined in `flake.nix` under `nixtest.suites`:

```bash
# Run all tests for a specific suite
nix run gitlab:technofab/nixtest -- run .#nixtest.suites.\"home-manager/claude\"
nix run gitlab:technofab/nixtest -- run .#nixtest.suites.\"devenv/claude\"
nix run gitlab:technofab/nixtest -- run .#nixtest.suites.\"presets/new\"
nix run gitlab:technofab/nixtest -- run .#nixtest.suites.\"nixos/opencode\"

# Available test suites:
# - home-manager/claude         - Home Manager native integration tests
# - home-manager/claude-install - Home Manager CLI installation tests
# - devenv/claude               - Devenv module tests
# - presets/new                 - Tests for config-normalizer, flake-analyst, code-intel, etc. (qdrant removed)
# - nixos/opencode              - NixOS opencode module tests
# - devenv/new-presets          - New presets in devenv context
# - home-manager/opencode          - Home Manager OpenCode integration tests
```

### Evaluating Flake Outputs
```bash
nix flake check                # Check flake validity
nix flake show                 # Show all flake outputs
nix eval .#<attr>              # Evaluate specific attribute
```

## Code Style Guidelines

### Nix Formatting (nixfmt-rfc-style)

Function arguments use destructuring on separate lines:
```nix
{
  lib,
  pkgs,
  config,
  ...
}: let
  # implementation
in { }
```

Group `inherit` statements at the top of let blocks:
```nix
let
  inherit
    (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    ;
in
```

### Module Patterns

Use standard NixOS module conventions:
```nix
{
  options.myModule = mkOption {
    type = types.submodule { ... };
    default = {};
    description = lib.mdDoc "Description using mdDoc";
  };

  config = mkIf cfg.enable {
    # configuration
  };
}
```

### Preset Definitions (presets.nix)

Follow the established preset pattern:
```nix
myPreset = {
  name = "My Preset";
  description = "Optional description";
  command = tools.getToolPath "my-tool";
  args = config: [ "--flag" config.someOption ];
  env = config: {
    MY_ENV_VAR = config.envValue;
  };
  options = {
    someOption = mkOption {
      type = types.str;
      description = lib.mdDoc "Option description";
      example = "example-value";
    };
  };
};
```

### Tool Definitions (tools.nix)

Use `mkTool` for simple tools, `wrapWithCredentialFiles` for tools needing secrets:
```nix
myTool = mkTool {
  package = pkgs.my-package;
  binary = "my-binary";
};

mySecureTool = mkTool {
  package = wrapWithCredentialFiles {
    package = pkgs.my-package;
    credentialEnvs = ["API_KEY" "AUTH_TOKEN"];
  };
  binary = "my-binary";
};
```

### Error Handling

Use `throw` for missing required configuration:
```nix
if tool.package == null
then throw "Tool ${name} is not available"
else tool.package
```

### Comments and Documentation

File headers use block comment style:
```nix
# =============================================================================
# File Description
#
# Additional context about complex areas
# =============================================================================
```

Use `lib.mdDoc` for option descriptions:
```nix
description = lib.mdDoc "Description with **markdown** support";
```

### Python Code Style (MCP Servers)

Python MCP servers in `nix/packages/` follow these conventions:

```python
"""Module docstring describing the MCP server."""

import json
from pathlib import Path

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("Server Name")


@mcp.tool()
def my_tool(param: str) -> str:
    """Tool docstring describing functionality."""
    # implementation
    return result


def main():
    """Entry point for the MCP server."""
    mcp.run()


if __name__ == "__main__":
    main()
```

Key conventions:
- Type hints for all function parameters and returns
- Docstrings for modules, classes, and functions
- Snake_case for functions and variables
- FastMCP decorator pattern for tool registration
- Standard entry point with `main()` function

## Security Considerations

- Never expose credentials in the Nix store
- Use `wrapWithCredentialFiles` for tools requiring API tokens
- Credential environment variables use `_FILEPATH` suffix pattern
- Always use file-based credential management over env vars

## Testing Patterns

Tests use nixtest with two types:
- `type = "unit"` - Direct value comparison
- `type = "script"` - Shell script execution

```nix
{
  tests = [
    {
      name = "descriptive test name";
      type = "unit";
      expected = { KEY = "value"; };
      actual = config.some.path;
    }
    {
      name = "script test";
      type = "script";
      script = ''
        # bash script that exits 0 on success
      '';
    }
  ];
}
```

## Adding New MCP Server Presets

1. Add package definition in `nix/packages/<name>/default.nix`
2. Add tool entry in `tools.nix` using `mkTool`
3. Add preset definition in `presets.nix`
4. Update overlay in `flake.nix` if needed
5. Add tests in `tests/` directory
6. Run `nix fmt` before committing

## Common Pitfalls

- Forgetting to add new packages to the overlay in `flake.nix`
- Missing `dontCheckRuntimeDeps = true` for Python packages with complex deps
- Not using `lib.mdDoc` for option descriptions
- Hardcoding paths instead of using `tools.getToolPath`
- Forgetting to handle `null` values in optional config options
