# MCP server that converts config files to LLM-friendly XML representation
{
  lib,
  python3Packages,
}:
python3Packages.buildPythonApplication {
  pname = "config-normalizer";
  version = "0.1.0";
  pyproject = true;

  src = ./.;

  build-system = [python3Packages.hatchling];

  dependencies = with python3Packages; [
    mcp
    pyyaml
    tomli
  ];

  # Skip checks during build
  dontCheckRuntimeDeps = true;
  pythonImportsCheck = [];
  doCheck = false;

  meta = {
    description = "MCP server that converts config files (JSON/YAML/TOML/INI) to LLM-friendly XML";
    mainProgram = "config-normalizer";
  };
}
