# MCP server that analyzes Nix flake.lock files into dependency reports
{
  lib,
  python3Packages,
}:
python3Packages.buildPythonApplication {
  pname = "flake-analyst";
  version = "0.1.0";
  pyproject = true;

  src = ./.;

  build-system = [python3Packages.hatchling];

  dependencies = with python3Packages; [
    mcp
  ];

  # Skip checks during build
  dontCheckRuntimeDeps = true;
  pythonImportsCheck = [];
  doCheck = false;

  meta = {
    description = "MCP server that analyzes Nix flake.lock files into dependency reports";
    mainProgram = "flake-analyst";
  };
}
