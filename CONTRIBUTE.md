# Contributing to Claude Code MCP Integration for Nix

Thank you for your interest in contributing to this project! This guide will help you get started with development and testing.

## Development Setup

To contribute or modify this project:

```bash
# Clone the repository
git clone https://github.com/roman/claude-code.nix
cd claude-code.nix

# Enter the development environment, this will install pre-commit hooks
nix develop

# Test with the example
cd examples/devenv-example
nix develop
```

## Testing

### Integration Tests

Run the integration tests to ensure everything works correctly:

```bash
# From the project root
./tests/integration.sh
```

### Testing with Examples

The project includes several example configurations you can test:

- `examples/devenv-example/` - Basic devenv integration
- `tests/fixtures/devenv-test/` - devenv test fixture
- `tests/fixtures/home-manager-test/` - Home Manager test fixture
- `tests/fixtures/edge-case-test/` - Edge case testing

## Project Structure

```
.
├── flake.nix                 # Main flake definition
├── presets.nix              # MCP server preset definitions
├── tools.nix                # Tool packaging and utilities
├── nix/
│   ├── lib/                  # Shared library functions
│   ├── modules/              # Nix modules for devenv and Home Manager
│   └── packages/             # Package definitions for MCP servers
├── examples/                 # Usage examples
└── tests/                    # Test fixtures and scripts
```

## Adding New MCP Servers

### Method 1: Using Presets

1. Add your preset definition to `presets.nix`:

```nix
my-server = {
  name = "My Server";
  command = tools.getToolPath "my-server";
  env = config: {
    API_KEY_FILEPATH = config.apiKeyFilepath;
  };
  options = {
    apiKeyFilepath = mkOption {
      type = types.str;
      description = lib.mdDoc "File containing API key";
      example = "/var/run/agenix/my-server.key";
    };
  };
};
```

2. (Optional, if server not available in [nixpkgs](https://github.com/NixOS/nixpkgs)) Add the package definition in `nix/packages/` :

```nix
# nix/packages/my-server/default.nix
  { lib, fetchFromGitHub, buildGoModule }:

buildGoModule {
  pname = "my-server";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "example";
    repo = "my-mcp-server";
    rev = "v1.0.0";
    hash = "sha256-...";
  };
  
  # ... rest of package definition
}
```

3. Update `tools.nix` to include your new package.

>!TIP
>
> If the program doesn't allow filepaths for token inputs, use the `wrapWithCredentialFiles` function
> with the mcp-server package derivation. Follow examples of other servers in the tools.nix file.
>
> This step is relevant as it will help avoid leaking credentials in the nix store.

### Method 2: Custom Servers

Users can also add custom servers directly in their configuration:

```nix
mcp.servers.my-custom-server = {
  type = "stdio";
  command = "${pkgs.my-mcp-server}/bin/server";
  args = [ "--option" "value" ];
  env = {
    API_KEY_FILE = "/path/to/api-key";
  };
};
```

## Security Considerations

- Always use file-based credential management instead of environment variables
- Never expose API tokens or keys in the Nix store
- Implement proper path restrictions for filesystem access
- Follow secure coding practices for new MCP server integrations

## Formatting and Linting

The project uses `nixfmt` for code formatting. Run formatting before submitting:

```bash
nix fmt
```

## Submitting Changes

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test your changes with the integration tests
5. Format your code with `nix fmt`
6. Submit a pull request

## Getting Help

If you need help or have questions:

- Open an issue on GitHub
- Check existing issues and discussions
- Review the examples and test fixtures for reference patterns

## License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.
