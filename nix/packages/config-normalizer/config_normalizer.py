"""MCP server that converts config files to LLM-friendly XML representation."""

import json
import configparser
from pathlib import Path

import yaml
import tomli
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("Universal Config Normalizer")


def to_xml(data, tag="item"):
    """Recursively convert data structure to XML string."""
    if isinstance(data, dict):
        return "\n".join(f"<{k}>{to_xml(v, k)}</{k}>" for k, v in data.items())
    elif isinstance(data, list):
        return "\n".join(f"<{tag}_entry>{to_xml(i, tag)}</{tag}_entry>" for i in data)
    return str(data)


@mcp.tool()
def normalize_config(file_path: str) -> str:
    """Convert a config file to structured XML format.

    Use this to parse complex configuration files into a consistent format.
    Supports: JSON, YAML (.yaml, .yml), TOML, INI
    """
    p = Path(file_path)
    if not p.exists():
        return "File not found"

    txt = p.read_text(encoding="utf-8")
    if p.suffix == ".json":
        data = json.loads(txt)
    elif p.suffix in [".yaml", ".yml"]:
        data = yaml.safe_load(txt)
    elif p.suffix == ".toml":
        data = tomli.loads(txt)
    elif p.suffix == ".ini":
        cp = configparser.ConfigParser()
        cp.read_string(txt)
        data = {s: dict(cp.items(s)) for s in cp.sections()}
    else:
        return "Unknown format"

    return f"<config file='{p.name}'>\n{to_xml(data)}\n</config>"


def main():
    """Entry point for the MCP server."""
    mcp.run()


if __name__ == "__main__":
    main()
