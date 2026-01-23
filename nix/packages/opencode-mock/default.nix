# Mock opencode package for testing the NixOS module
# This provides a minimal /bin/opencode binary that can be used
# to verify module configuration without requiring the real package.
{writeShellScriptBin}:
writeShellScriptBin "opencode" ''
  echo "mock opencode: $@"
  # Support basic subcommands for testing
  case "$1" in
    web)
      echo "Starting mock web server..."
      # Just exit successfully for testing
      ;;
    --version)
      echo "opencode-mock 0.0.0-test"
      ;;
    *)
      echo "Unknown command: $1"
      ;;
  esac
''
