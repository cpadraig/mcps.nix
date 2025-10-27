{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    nixDir.url = "github:roman/nixDir/v3";

    devenv.url = "github:cachix/devenv";
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    systems.url = "github:nix-systems/default";
    systems.flake = false;
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = [
        inputs.devenv.flakeModule
        inputs.nixDir.flakeModule
      ];

      nixDir = {
        root = ./.;
        enable = true;
        nixpkgsConfig = {
          allowUnfree = true;
        };
        installOverlays = [
          (
            _final: prev:
            let
              unstable-pkgs = import inputs.nixpkgs-unstable { inherit (prev) system; };
            in
            {
              inherit (inputs) uv2nix pyproject pyproject-build-systems;
              inherit (unstable-pkgs) github-mcp-server;
            }
          )
        ];
        generateAllPackage = true;
      };

      perSystem =
        { system, config, ... }:
        {
          devenv.shells.default =
            { pkgs, config, ... }:
            {
              imports = [ inputs.self.devenvModules.claude-code ];

              git-hooks.hooks = {
                nixfmt-rfc-style.enable = true;
              };

              claude-code = {
                enable = true;
                mcp.lsp-nix = {
                  enable = true;
                  workspace = config.devenv.root;
                };
              };

            };
        };
    };
}
