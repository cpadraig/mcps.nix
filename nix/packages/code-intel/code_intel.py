"""MCP server for code structure analysis via Tree-Sitter."""

import os
from pathlib import Path

from tree_sitter import Language, Parser
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("Code Intel (Tree-Sitter)")

# Map file extensions to their language name (grammar paths passed via env vars)
LANG_MAP = {".py": "python", ".nix": "nix", ".java": "java"}


def get_language_parser(lang_name):
    """
    Load the Tree-Sitter language using the grammar path provided by Nix.
    Expects env var: TREE_SITTER_{LANG}_GRAMMAR
    """
    env_var = f"TREE_SITTER_{lang_name.upper()}_GRAMMAR"
    grammar_path = os.environ.get(env_var)

    if not grammar_path:
        raise ValueError(
            f"Grammar for {lang_name} not found. Env var {env_var} is missing."
        )

    # Language(path, name) loads the compiled grammar from the shared object
    lang = Language(grammar_path, lang_name)
    parser = Parser()
    parser.set_language(lang)
    return lang, parser


def get_definitions(node, lang_name):
    """Extract definitions from a syntax tree node."""
    defs = []
    # Adjust node types based on language if necessary
    target_types = ["function_definition", "class_definition", "method_declaration"]
    if lang_name == "nix":
        target_types = ["binding"]  # simplified for Nix

    if node.type in target_types:
        name_node = node.child_by_field_name("name")
        # Fallback for languages where name field might differ
        if not name_node and lang_name == "nix":
            name_node = node.child_by_field_name("attrpath")

        if name_node:
            defs.append(f"{node.type}: {name_node.text.decode('utf-8')}")

    for child in node.children:
        defs.extend(get_definitions(child, lang_name))
    return defs


@mcp.tool()
def get_code_structure(file_path: str) -> str:
    """Extract high-level structure (classes, functions, bindings) from a source file.

    Use this to understand file organization without reading the entire file.
    Supports: Python (.py), Nix (.nix), Java (.java)
    """
    path = Path(file_path)
    lang_name = LANG_MAP.get(path.suffix)
    if not lang_name:
        return "Unsupported language"

    try:
        _, parser = get_language_parser(lang_name)
        tree = parser.parse(path.read_bytes())
        return f"File: {path.name}\n\n" + "\n".join(
            get_definitions(tree.root_node, lang_name)
        )
    except Exception as e:
        return f"Error parsing: {e}"


def main():
    """Entry point for the MCP server."""
    mcp.run()


if __name__ == "__main__":
    main()
