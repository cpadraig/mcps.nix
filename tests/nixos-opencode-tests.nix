# Tests for NixOS opencode-server module
# These tests verify the NixOS module configuration structure is correct
# Note: Full NixOS evaluation would require more infrastructure,
# so these tests focus on module existence and basic structure verification
{
  inputs,
  pkgs,
  system,
  ...
}: let
  # Get pkgs with overlay for mock package
  testPkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [inputs.self.overlays.default];
  };

  # Read the module source to verify structure
  moduleSource = builtins.readFile ../nix/modules/nixos/opencode/default.nix;

  # Check that the module is a function (proper NixOS module format)
  moduleIsFunction = builtins.isFunction (import ../nix/modules/nixos/opencode);

  # Verify the flake exports the module
  nixosModulesExist = inputs.self ? nixosModules;
  opencodeModuleExists = inputs.self.nixosModules ? opencode;

  # Verify overlay includes mock package for testing
  overlayHasMock = testPkgs ? opencode-mock;
in {
  tests = [
    # ========================================
    # Module Export Tests
    # ========================================
    {
      name = "flake exports nixosModules";
      type = "unit";
      expected = true;
      actual = nixosModulesExist;
    }
    {
      name = "nixosModules contains opencode";
      type = "unit";
      expected = true;
      actual = opencodeModuleExists;
    }
    {
      name = "opencode module is a function";
      type = "unit";
      expected = true;
      actual = moduleIsFunction;
    }

    # ========================================
    # Module Source Structure Tests
    # ========================================
    {
      name = "module declares services.opencode-server option";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "services.opencode-server" "$MODULE_SRC"; then
          echo "Module does not declare services.opencode-server"
          exit 1
        fi
      '';
    }
    {
      name = "module declares enable option";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "mkEnableOption" "$MODULE_SRC"; then
          echo "Module does not use mkEnableOption"
          exit 1
        fi
      '';
    }
    {
      name = "module declares package option";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "types.package" "$MODULE_SRC"; then
          echo "Module does not declare package option"
          exit 1
        fi
      '';
    }
    {
      name = "module declares port option";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "types.port" "$MODULE_SRC"; then
          echo "Module does not declare port option"
          exit 1
        fi
      '';
    }
    {
      name = "module declares hostname option";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "hostname" "$MODULE_SRC"; then
          echo "Module does not declare hostname option"
          exit 1
        fi
      '';
    }
    {
      name = "module declares mcps option";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "mcps = mkOption" "$MODULE_SRC"; then
          echo "Module does not declare mcps option"
          exit 1
        fi
      '';
    }

    # ========================================
    # Systemd Service Structure Tests
    # ========================================
    {
      name = "module creates systemd service";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "systemd.services.opencode-server" "$MODULE_SRC"; then
          echo "Module does not create systemd service"
          exit 1
        fi
      '';
    }
    {
      name = "systemd service has hardening options";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "ProtectSystem" "$MODULE_SRC"; then
          echo "Module does not include ProtectSystem hardening"
          exit 1
        fi
        if ! ${pkgs.gnugrep}/bin/grep -q "NoNewPrivileges" "$MODULE_SRC"; then
          echo "Module does not include NoNewPrivileges hardening"
          exit 1
        fi
      '';
    }
    {
      name = "systemd service sets OPENCODE_CONFIG";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "OPENCODE_CONFIG" "$MODULE_SRC"; then
          echo "Module does not set OPENCODE_CONFIG environment"
          exit 1
        fi
      '';
    }

    # ========================================
    # User/Group Tests
    # ========================================
    {
      name = "module creates opencode user";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "users.users" "$MODULE_SRC"; then
          echo "Module does not create users"
          exit 1
        fi
      '';
    }
    {
      name = "module creates opencode group";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "users.groups" "$MODULE_SRC"; then
          echo "Module does not create groups"
          exit 1
        fi
      '';
    }

    # ========================================
    # Firewall Tests
    # ========================================
    {
      name = "module configures firewall";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "networking.firewall.allowedTCPPorts" "$MODULE_SRC"; then
          echo "Module does not configure firewall"
          exit 1
        fi
      '';
    }

    # ========================================
    # MCP Server Configuration Tests
    # ========================================

    {
      name = "module generates JSON config";
      type = "script";
      script = ''
        MODULE_SRC="${builtins.toFile "module.nix" moduleSource}"
        if ! ${pkgs.gnugrep}/bin/grep -q "builtins.toJSON" "$MODULE_SRC"; then
          echo "Module does not generate JSON config"
          exit 1
        fi
      '';
    }

    # ========================================
    # Overlay Mock Package Tests
    # ========================================
    {
      name = "overlay provides opencode-mock package";
      type = "unit";
      expected = true;
      actual = overlayHasMock;
    }
    {
      name = "opencode-mock is executable";
      type = "script";
      script = ''
        if [ ! -x "${testPkgs.opencode-mock}/bin/opencode" ]; then
          echo "opencode-mock is not executable"
          exit 1
        fi
      '';
    }
  ];
}
