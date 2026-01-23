{
  lib,
  tools,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    ;

  mcpServerOptionsType = import ./nix/lib/mcp-server-options.nix lib;

  # Helper to transform a simple preset definition into a full module
  # NOTE: Uses toolName instead of command to avoid IFD during option definition.
  # The actual command path is resolved lazily inside config = mkIf config.enable.
  mkPresetModule =
    {
      name,
      description ? "MCP integration for ${name}",
      options ? { },
      env ? (_: { }),
      toolName,
      args ? (_: [ ]),
    }:
    { config, ... }:
    {
      options = {
        enable = mkEnableOption description;

        mcpServer = mkOption {
          type = lib.types.submodule mcpServerOptionsType;
          default = { };
          description = lib.mdDoc "MCP server configuration";
        };
      }
      // options;

      config = mkIf config.enable {
        mcpServer = {
          type = "stdio";
          # Resolve tool path lazily here (only when enabled) to avoid IFD during evaluation
          command = tools.getToolPath toolName;
          args = args config;
          env = builtins.mapAttrs (_k: v: builtins.toString v) (env config);
        };
      };
    };

  # Simple preset definitions
  presets = {

    asana = {
      name = "Asana";
      toolName = "asana";
      env = config: {
        ASANA_ACCESS_TOKEN_FILEPATH = config.tokenFilepath;
      };
      options = {
        tokenFilepath = mkOption {
          type = types.str;
          description = lib.mdDoc "File containing Asana API access token";
          example = "/var/run/agenix/asana.token";
        };
      };
    };

    filesystem = {
      name = "Filesystem";
      description = "Read, write, and list files within allowed directories. Use for file operations in sandboxed paths.";
      toolName = "filesystem";
      args = config: config.allowedPaths;
      options = {
        allowedPaths = mkOption {
          type = types.nonEmptyListOf types.str;
          description = lib.mdDoc "List of allowed filepaths that your agent can explore";
          example = [ "/Users/jdoe/Projects" ];
        };
      };
    };

    git = {
      name = "Git";
      description = "Execute git operations: status, diff, log, blame, show, commit. Use instead of shell git commands.";
      toolName = "git";
      env = _config: {
        # Reset PYTHONPATH to avoid environmental dependencies affecting the runtime
        # of this application.
        PYTHONPATH = "";
        # GitPython requires the git binary to be available in PATH
        PATH = lib.makeBinPath [ pkgs.git ];
      };
    };

    fetch = {
      name = "Fetch";
      description = "Fetch and parse web content from URLs. Use for documentation and external resources.";
      toolName = "fetch";
      args =
        config:
        (lib.optionals (config.userAgent != null) [
          "--user-agent"
          config.userAgent
        ])
        ++ (lib.optionals (config.proxyURL != null) [
          "--proxy-url"
          config.proxyURL
        ])
        ++ (lib.optionals config.ignoreRobotsTxt [ "--ignore-robots-txt" ]);
      env = _config: {
        # Reset PYTHONPATH to avoid environmental dependencies affecting the runtime
        # of this application.
        PYTHONPATH = "";
      };
      options = {
        proxyURL = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = lib.mdDoc "Proxy URL to use for requests";
          example = "https://localhost:3000";
        };
        ignoreRobotsTxt = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc "Ignore robots.txt restrictions";
          example = false;
        };
        userAgent = mkOption {
          type = types.nullOr types.str;
          description = lib.mdDoc "Custom User-Agent string";
          default = null;
          example = "claude-code";
        };
      };
    };

    sequential-thinking = {
      name = "Sequential Thinking";
      description = "Step-by-step reasoning for complex problem decomposition and multi-step planning.";
      toolName = "sequential-thinking";
    };

    time = {
      name = "Time";
      description = "Get current time and timezone information for time-sensitive operations.";
      toolName = "time";
      args =
        config:
        lib.optionals (config.localTimezone != null) [
          "--local-timezone"
          config.localTimezone
        ];
      env = _config: {
        # Reset PYTHONPATH to avoid environmental dependencies affecting the runtime
        # of this application.
        PYTHONPATH = "";
      };
      options = {
        localTimezone = mkOption {
          type = types.str;
          description = lib.mdDoc "Timezone used by the server";
          example = "America/New_York";
        };
      };
    };

    github = {
      name = "GitHub";
      toolName = "github";
      args = config: [
        "stdio"
        "--toolsets"
        (builtins.concatStringsSep "," config.toolsets)
      ];
      env =
        config:
        {
          GITHUB_PERSONAL_ACCESS_TOKEN_FILEPATH = config.tokenFilepath;
        }
        // (lib.optionalAttrs (config.baseURL != null && config.baseURL != "") {
          GITHUB_HOST = config.baseURL;
        });
      options = {
        tokenFilepath = mkOption {
          type = types.str;
          description = lib.mdDoc "File containing GitHub API access token";
          example = "/var/run/agenix/gh-personal-access.token";
        };

        baseURL = mkOption {
          type = types.nullOr types.str;
          description = lib.mdDoc "Use it for GitHub Enterprise Cloud installs";
          example = "https://<your GHES or ghe.com domain name>";
        };

        toolsets = mkOption {
          type = types.nonEmptyListOf (
            types.enum [
              "context" # Strongly recommended: Tools that provide context about the current user and GitHub context you are operating in
              "actions" # GitHub Actions workflows and CI/CD operations
              "code_security" # Code security related tools, such as GitHub Code Scanning
              "dependabot" # Dependabot tools
              "discussions" # GitHub Discussions related tools
              "experiments" # Experimental features that are not considered stable yet
              "gists" # GitHub Gist related tools
              "issues" # GitHub Issues related tools
              "labels" # GitHub Labels related tools
              "notifications" # GitHub Notifications related tools
              "orgs" # GitHub Organization related tools
              "projects" # GitHub Projects related tools
              "pull_requests" # GitHub Pull Request related tools
              "repos" # GitHub Repository related tools
              "secret_protection" # Secret protection related tools, such as GitHub Secret Scanning
              "security_advisories" # Security advisories related tools
              "stargazers" # GitHub Stargazers related tools
              "users" # GitHub User related tools
            ]
          );
          default = [
            "context"
            "repos"
            "pull_requests"
            "users"
          ];
          description = lib.mdDoc "List of GitHub toolsets to enable";
        };
      };
    };

    grafana = {
      name = "Grafana";
      toolName = "grafana";
      args =
        config:
        [
          "-enabled-tools"
          (builtins.concatStringsSep "," config.toolsets)
        ]
        ++ (lib.optionals config.debug [ "-debug" ]);

      env = config: {
        GRAFANA_URL = config.baseURL;
        GRAFANA_API_KEY_FILEPATH = config.apiKeyFilepath;
      };

      options = {
        apiKeyFilepath = mkOption {
          type = types.str;
          description = lib.mdDoc "File containing Grafana API key";
          example = "/var/run/agenix/grafana-api.key";
        };

        baseURL = mkOption {
          type = types.str;
          description = lib.mdDoc "URL where the Grafana host lives";
          example = "https://localhost:3000";
        };

        toolsets = mkOption {
          type = types.nonEmptyListOf (
            types.enum [
              "search"
              "datasource"
              "incident"
              "prometheus"
              "loki"
              "alerting"
              "dashboard"
              "oncall"
              "asserts"
              "sift"
              "admin"
            ]
          );
          default = [
            "prometheus"
            "search"
            "datasource"
          ];
          description = lib.mdDoc "List of Grafana toolsets to enable";
        };

        debug = mkOption {
          type = types.bool;
          description = lib.mdDoc "Enable debug mode for the Grafana transport";
          default = false;
          example = "true";
        };
      };
    };

    buildkite = {
      name = "Buildkite";
      toolName = "buildkite";
      args = _config: [ "stdio" ];
      env = config: {
        BUILDKITE_API_TOKEN_FILEPATH = config.apiKeyFilepath;
      };
      options = {
        apiKeyFilepath = mkOption {
          type = types.str;
          description = lib.mdDoc "File containing Buildkite API token";
          example = "/var/run/agenix/buildkite-api.token";
        };
      };
    };

    lsp-golang = {
      name = "LSP (Golang)";
      toolName = "lsp";
      args = config: [
        "--workspace"
        config.workspace
        "--lsp"
        config.lspPackage.meta.mainProgram
      ];
      env =
        config:
        (
          {
            PATH = lib.makeBinPath [
              config.lspPackage
              config.goPackage
            ];
          }
          // (if config.GOROOT != null then { GOROOT = config.GOROOT; } else { })
          // (if config.GOCACHE != null then { GOCACHE = config.GOCACHE; } else { })
          // (if config.GOMODCACHE != null then { GOMODCACHE = config.GOMODCACHE; } else { })
        );

      options = {
        lspPackage = mkOption {
          type = types.package;
          description = "package for golang's LSP server";
          default = pkgs.gopls;
        };

        goPackage = mkOption {
          type = types.package;
          description = "go package";
          default = pkgs.go;
        };

        workspace = mkOption {
          type = types.str;
          description = "workspace where the lsp-server will run";
        };

        GOROOT = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "GOROOT used by gopls";
        };

        GOCACHE = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "GOCACHE used by gopls";
        };

        GOMODCACHE = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "GOMODCACHE used by gopls";
        };
      };
    };

    lsp-typescript = {
      name = "LSP (Typescript)";
      toolName = "lsp";
      args = config: [
        "--workspace"
        config.workspace
        "--lsp"
        config.lspPackage.meta.mainProgram
      ];
      env = _config: {
        PATH = lib.makeBinPath [ pkgs.typescript-language-server ];
      };
      options = {

        lspPackage = mkOption {
          type = types.package;
          default = pkgs.typescript-language-server;
          description = "package for typescript's LSP server";
        };

        workspace = mkOption {
          type = types.str;
          description = "workspace where the lsp-server will run";
        };

      };
    };

    lsp-python = {
      name = "LSP (Python)";
      toolName = "lsp";
      args = config: [
        "--workspace"
        config.workspace
        "--lsp"
        config.lspPackage.meta.mainProgram
        "--"
        "--stdio"
      ];

      env = config: {
        PATH = lib.makeBinPath [ config.lspPackage ];
      };

      options = {

        lspPackage = mkOption {
          type = types.package;
          default = pkgs.pyright;
          description = "package for python's LSP server";
        };

        workspace = mkOption {
          type = types.str;
          description = "workspace where the lsp-server will run";
        };

      };
    };

    lsp-rust = {
      name = "LSP (Rust)";
      toolName = "lsp";
      args = config: [
        "--workspace"
        config.workspace
        "--lsp"
        config.lspPackage.meta.mainProgram
      ];

      env = config: {
        PATH = lib.makeBinPath [ config.lspPackage ];
      };

      options = {

        lspPackage = mkOption {
          type = types.package;
          default = pkgs.rust-analyzer;
          description = "package for rust's LSP server";
        };

        workspace = mkOption {
          type = types.str;
          description = "workspace where the lsp-server will run";
        };

      };
    };

    lsp-nix = {
      name = "LSP (Nix)";
      toolName = "lsp";
      args = config: [
        "--workspace"
        config.workspace
        "--lsp"
        config.lspPackage.meta.mainProgram
      ];

      env = config: {
        PATH = lib.makeBinPath [ config.lspPackage ];
      };

      options = {

        lspPackage = mkOption {
          type = types.package;
          default = pkgs.nil;
          description = "package for nix's LSP server";
        };

        workspace = mkOption {
          type = types.str;
          description = "workspace where the lsp-server will run";
        };

      };
    };

    obsidian = {
      name = "Obsidian";
      toolName = "obsidian";

      args = _config: [ ];

      env = config: {
        OBSIDIAN_API_KEY_FILEPATH = config.apiKeyFilepath;
        OBSIDIAN_HOST = config.host;
        OBSIDIAN_PORT = config.port;
      };

      options = {

        host = mkOption {
          type = types.str;
          description = lib.mdDoc "Host of the obisidan server";
          default = "127.0.0.1";
        };

        port = mkOption {
          type = types.number;
          description = lib.mdDoc "Port of the obisidian server";
          default = 27124;
        };

        apiKeyFilepath = mkOption {
          type = types.str;
          description = lib.mdDoc "File containing Obsidian Key";
          example = "/var/run/agenix/obisidian.key";
        };

      };
    };

    ast-grep = {
      name = "ast-grep";
      description = "MCP server for ast-grep structural code search and transformation";
      toolName = "ast-grep";
      args =
        config:
        lib.optionals (config.configFile != null) [
          "--config"
          config.configFile
        ];
      options = {
        configFile = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = lib.mdDoc "Path to sgconfig.yaml file for customizing ast-grep behavior";
          example = "/path/to/sgconfig.yaml";
        };
      };
    };

    nixos = {
      name = "NixOS";
      description = "Query NixOS and Home Manager option documentation: types, defaults, descriptions, and examples.";
      toolName = "nixos";
      args = _config: [ ];
      env = _config: { };
      options = { };
    };

    config-normalizer = {
      name = "Config Normalizer";
      description = "Converts config files (JSON/YAML/TOML/INI) to LLM-friendly XML";
      toolName = "config-normalizer";
      args = _config: [ ];
      env = _config: { };
      options = { };
    };

    flake-analyst = {
      name = "Flake Analyst";
      description = "Parses Nix flake.lock files into dependency reports";
      toolName = "flake-analyst";
      args = _config: [ ];
      env = _config: { };
      options = { };
    };

    code-intel = {
      name = "Code Intel";
      description = "Extracts code structure (classes, functions) via Tree-Sitter";
      toolName = "code-intel";
      args = _config: [ ];
      env = _config: { };
      options = {
        languages = mkOption {
          type = types.listOf (types.enum [ "python" "nix" "java" ]);
          default = [ "python" "nix" "java" ];
          description = lib.mdDoc "Languages to enable for code structure analysis";
          example = [ "python" "nix" ];
        };
      };
    };

  };

in
lib.mapAttrs (_: mkPresetModule) presets
