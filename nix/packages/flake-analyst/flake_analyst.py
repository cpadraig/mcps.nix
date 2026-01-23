"""MCP server that analyzes Nix flake.lock files into dependency reports."""

import json
from pathlib import Path

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("Flake Analyst")


def resolve(nodes, name, stack=None):
    """Resolve a node from flake.lock into a markdown description."""
    if stack is None:
        stack = []
    if name in stack or name not in nodes:
        return ""
    node = nodes[name]
    locked = node.get("locked", {})
    src = f"{locked.get('owner', '?')}/{locked.get('repo', '?')}"
    rev = locked.get("rev", "")[:7]
    out = f"### {name}\n- **Src**: {src}\n- **Rev**: {rev}\n"
    inputs = node.get("inputs", {})
    if inputs:
        out += "- **Inputs**: " + ", ".join(inputs.keys()) + "\n"
    return out


@mcp.tool()
def parse_flake_lock(path: str) -> str:
    """Parse a flake.lock file into a dependency report.

    Use this to understand flake inputs, their sources, revisions, and relationships.
    Returns markdown-formatted dependency tree.
    """
    try:
        data = json.loads(Path(path).read_text())
        nodes = data.get("nodes", {})
        root = data.get("root", "root")
        report = [f"# Flake Analysis: {path}\n"]
        report.append(resolve(nodes, root))
        report.append("\n## All Dependencies")
        report.extend([resolve(nodes, k) for k in nodes if k != root])
        return "\n".join(report)
    except Exception as e:
        return str(e)


def main():
    """Entry point for the MCP server."""
    mcp.run()


if __name__ == "__main__":
    main()
