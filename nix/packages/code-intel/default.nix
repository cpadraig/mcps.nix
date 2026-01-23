# MCP server for code structure analysis via Tree-Sitter
{
  lib,
  pkgs,
  python3Packages,
  makeWrapper,
  symlinkJoin,
}: let
  # Helper to get grammar path for a language
  getGrammar = name: "${pkgs.tree-sitter.builtGrammars.${"tree-sitter-${name}"}}/parser";

  basePackage = python3Packages.buildPythonApplication {
    pname = "code-intel";
    version = "0.1.0";
    pyproject = true;

    src = ./.;

    build-system = [python3Packages.hatchling];

    dependencies = with python3Packages; [
      mcp
      tree-sitter
    ];

    # Skip checks during build
    dontCheckRuntimeDeps = true;
    pythonImportsCheck = [];
    doCheck = false;

    meta = {
      description = "MCP server for code structure analysis via Tree-Sitter";
      mainProgram = "code-intel";
    };
  };
in
  # Wrapper that injects grammar paths for all supported languages
  symlinkJoin {
    name = "code-intel-wrapped";
    paths = [basePackage];
    nativeBuildInputs = [makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/code-intel \
        --set TREE_SITTER_PYTHON_GRAMMAR "${getGrammar "python"}" \
        --set TREE_SITTER_NIX_GRAMMAR "${getGrammar "nix"}" \
        --set TREE_SITTER_JAVA_GRAMMAR "${getGrammar "java"}"
    '';
    meta = {
      description = "MCP server for code structure analysis via Tree-Sitter";
      mainProgram = "code-intel";
    };
  }
