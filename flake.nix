{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    nixDir.url = "github:roman/nixDir/v3";
    nixDir.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    home-manager-unstable.url = "github:nix-community/home-manager";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # Used to run integration tests with nixosTest
    # mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";

    mcp-nixos.url = "github:utensils/mcp-nixos/v1.1.0";
    mcp-nixos.inputs.nixpkgs.follows = "nixpkgs";

    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";

    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";

    ## Dependencies to build mcp-servers
    pyproject = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixtest.url = "gitlab:technofab/nixtest?dir=lib";

    systems.url = "github:nix-systems/default";
    systems.flake = false;
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = import inputs.systems;

      imports = [
        inputs.devenv.flakeModule
        inputs.nixDir.flakeModule
        inputs.nixtest.flakeModule
      ];

      nixDir = {
        root = ./.;
        enable = true;
        nixpkgsConfig = {
          allowUnfree = true;
        };
        installOverlays = [
          inputs.self.overlays.default
        ];
        generateAllPackage = true;
      };

      flake.overlays = {
        default = final: prev: let
          unstable-pkgs = import inputs.nixpkgs-unstable {inherit (prev) system;};

          # Python with patched fastmcp for mcp 1.25.0 compatibility
          patchedPython3 = prev.python3.override {
            self = patchedPython3;
            packageOverrides = pyfinal: pyprev: {
              # Package py-key-value-aio (dependency of pydocket) - use wheel
              py-key-value-aio = pyfinal.buildPythonPackage rec {
                pname = "py_key_value_aio";
                version = "0.3.0";
                format = "wheel";

                src = prev.fetchPypi {
                  inherit pname version;
                  format = "wheel";
                  dist = "py3";
                  python = "py3";
                  hash = "sha256-HHgZFXZgeL/WCNqnaf77l+ZdHXN0aj37ZARg4yIHG2Q=";
                };

                dependencies = with pyfinal; [
                  redis
                ];

                pythonImportsCheck = [];
                doCheck = false;
                dontCheckRuntimeDeps = true;
              };

              # Package pydocket (imports as 'docket') - use wheel
              pydocket = pyfinal.buildPythonPackage rec {
                pname = "pydocket";
                version = "0.16.3";
                format = "wheel";

                src = prev.fetchPypi {
                  inherit pname version;
                  format = "wheel";
                  dist = "py3";
                  python = "py3";
                  hash = "sha256-4rUJJTVufNU1KGJVGVRYrHu6FfJSkzVmUbNtIj213Xw=";
                };

                dependencies = with pyfinal; [
                  cloudpickle
                  fakeredis
                  opentelemetry-api
                  prometheus-client
                  pyfinal.py-key-value-aio
                  python-json-logger
                  redis
                  rich
                  typer
                  typing-extensions
                ];

                pythonImportsCheck = [];
                doCheck = false;
                dontCheckRuntimeDeps = true;
              };

              fastmcp = pyprev.fastmcp.overridePythonAttrs (old: rec {
                version = "2.14.2";
                src = prev.fetchFromGitHub {
                  owner = "jlowin";
                  repo = "fastmcp";
                  rev = "v${version}";
                  hash = "sha256-JqDsHmhuRom4CPmQd0sMaBtgypHDtwVJ4I3fnOLjnd8=";
                };
                # Add new deps required by 2.14.2
                dependencies =
                  (old.dependencies or [])
                  ++ [
                    pyfinal.platformdirs
                    pyfinal.pydocket
                  ];
                dontCheckRuntimeDeps = true;
                pythonImportsCheck = [];
                doCheck = false;
              });
            };
          };
        in {
          inherit (inputs) uv2nix pyproject pyproject-build-systems;
          inherit (unstable-pkgs) github-mcp-server;

          python3 = patchedPython3;
          python3Packages = patchedPython3.pkgs;

          # Build mcp-nixos with patched python3
          mcp-nixos = patchedPython3.pkgs.buildPythonApplication {
            pname = "mcp-nixos";
            version = "1.1.0";
            pyproject = true;

            src = inputs.mcp-nixos;

            build-system = [patchedPython3.pkgs.hatchling];

            dependencies = with patchedPython3.pkgs; [
              fastmcp
              requests
              beautifulsoup4
            ];

            dontCheckRuntimeDeps = true;
            pythonImportsCheck = [];
            doCheck = false;

            meta = {
              description = "MCP server for NixOS";
              mainProgram = "mcp-nixos";
            };
          };

          # Expose all MCP packages from nix/packages/
          mcp-servers = final.callPackage ./nix/packages/mcp-servers {};
          mcp-language-server = final.callPackage ./nix/packages/mcp-language-server {};
          ast-grep-mcp = final.callPackage ./nix/packages/ast-grep-mcp {};
          mcp-grafana = final.callPackage ./nix/packages/mcp-grafana {};
          mcp-obsidian = final.callPackage ./nix/packages/mcp-obsidian {};
          buildkite-mcp-server = final.callPackage ./nix/packages/buildkite-mcp-server {};
          mcp-server-asana = final.callPackage ./nix/packages/mcp-server-asana {};
        };
      };

      perSystem = {
        pkgs,
        system,
        ...
      }: {
        nixtest.suites = {
          "home-manager/claude" = import ./tests/home-manager-claude-tests.nix {
            inherit inputs pkgs system;
          };

          "home-manager/claude-install" = import ./tests/home-manager-claude-install-tests.nix {
            inherit inputs pkgs system;
          };

          "devenv/claude" = import ./tests/devenv-claude-tests.nix {
            inherit inputs pkgs system;
          };
        };

        devenv.shells.default = {
          config,
          ...
        }: {
          imports = [inputs.self.devenvModules.claude];

          git-hooks.hooks = {
            nixfmt-rfc-style.enable = true;
          };

          claude.code = {
            enable = true;
            mcps.lsp-nix = {
              enable = true;
              workspace = config.devenv.root;
            };
          };
        };
      };
    };
}
