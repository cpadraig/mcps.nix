# =============================================================================
# NixOS OpenCode Service Template
#
# Complete NixOS configuration for system-level OpenCode deployment
# Includes systemd service, user management, firewall, and MCP integration
#
# Usage: Include this configuration in your NixOS configuration
# =============================================================================
{
  description = "NixOS OpenCode Service";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mcps.url = "github:your-org/mcps.nix";
  };

  outputs = { nixpkgs, mcps, ... }: {
    nixosConfigurations = {
      # Example configuration for a server
      opencode-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        
        modules = [
          mcps.nixosModules.opencode
          
          {
            # OpenCode system service configuration
            services.opencode-server = {
              enable = true;
              user = "opencode";
              group = "opencode";
              port = 3000;
              host = "0.0.0.0";
              
              # MCP configurations (system-wide)
              mcps = {
                # Essential token-efficient MCPs (per todo.md)
                nixos.enable = true;          # System introspection
                config-normalizer.enable = true; # Config file processing
                flake-analyst.enable = true;   # Nix flake analysis
                code-intel = {
                  enable = true;
                  languages = ["python" "nix" "java" "bash"];
                };
                ast-grep.enable = true;        # Structural code search
                
                # System integration tools
                filesystem = {
                  enable = true;
                  allowedPaths = [
                    "/home/opencode/projects"
                    "/etc/nixos"
                    "/var/log"
                  ];
                };
                
                # External service integrations
                github = {
                  enable = true;
                  tokenFilepath = "/var/lib/secrets/github-opencode.token";
                  toolsets = ["context" "repos" "pull_requests" "users"];
                };
                grafana = {
                  enable = true;
                  baseURL = "https://grafana.company.com";
                  apiKeyFilepath = "/var/lib/secrets/grafana-opencode.key";
                  toolsets = ["prometheus" "search" "datasource" "dashboard"];
                };
                
                # LSP services for multiple languages
                lsp-nix = {
                  enable = true;
                  workspace = "/home/opencode/projects";
                };
                lsp-python = {
                  enable = true;
                  workspace = "/home/opencode/projects";
                };
                lsp-java = {
                  enable = true;
                  workspace = "/home/opencode/projects";
                };
                
                # Time and planning
                time = {
                  enable = true;
                  localTimezone = "UTC";
                };
                sequential-thinking.enable = true;
              };
              
              # Security settings
              security = {
                enable = true;
                apiKeyFilepath = "/var/lib/secrets/opencode-api.key";
                allowedOrigins = ["https://app.opencode.ai"];
                enableCors = true;
              };
              
              # Performance tuning
              performance = {
                maxMemoryMB = 2048;
                maxConnections = 100;
                enableMetrics = true;
                enableTracing = false;
              };
            };

            # User and group management
            users.users.opencode = {
              isSystemUser = true;
              group = "opencode";
              description = "OpenCode service user";
              home = "/home/opencode";
              createHome = true;
            };

            users.groups.opencode = {};

            # Firewall configuration
            networking.firewall = {
              enable = true;
              allowedTCPPorts = [3000];
              allowedUDPPorts = [];
            };

            # Ensure required directories exist
            systemd.tmpfiles.rules = [
              "d /var/lib/secrets 0750 opencode opencode -"
              "d /home/opencode/projects 0755 opencode opencode -"
              "d /var/log/opencode 0755 opencode opencode -"
            ];

            # System packages needed for OpenCode
            environment.systemPackages = with nixpkgs; [
              git
              curl
              wget
              vim
              nixfmt-rfc-style
            ];

            # Optional: Enable Ollama for local LLM
            services.ollama = {
              enable = true;
              user = "opencode";
              group = "opencode";
              acceleration = "cuda"; # or "rocm" for AMD
            };

            # Logging configuration
            services.journald.extraConfig = ''
              [Storage]
              SystemMaxUse=50G
              
              [Journal]
              Storage=persistent
              Compress=yes
              SystemMaxRetentionSec=30day
            '';

            # Backup configuration (optional)
            services.borgbackup.jobs."opencode-backup" = {
              paths = [
                "/home/opencode/projects"
                "/var/lib/opencode"
              ];
              exclude = [
                "/home/opencode/projects/**/.git"
                "/home/opencode/projects/**/node_modules"
                "/home/opencode/projects/**/target"
                "/home/opencode/projects/**/build"
              ];
              repo = "backup@backup-server.com:/backups/opencode";
              encryption = {
                mode = "repokey-blake2";
                passCommand = "cat /var/lib/secrets/borg-passphrase";
              };
              compression = "auto,zstd";
              startAt = "daily";
            };

            # Monitoring (optional)
            services.prometheus = {
              enable = true;
              port = 9090;
              exporters = [
                {
                  port = 9100;
                  enabledCollectors = ["systemd" "process" "filesystem"];
                }
              ];
            };

            # Security hardening
            security.apparmor.enable = true;
            security.auditd.enable = true;

            # System state version
            system.stateVersion = "25.11";
          }
        ];
      };
    };
  };
}