# ISO VM test library.
# Provides real runtime VM tests for the installer ISO module.
{
  pkgs,
  lib,
  nixpkgs,
  disko,
  self,
  system,
}: let
  assertions = import ../../../lib/vm/assertions.nix;

  installerIsoModules = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ../../../../iso
  ];

  testInstrumentationModule = "${nixpkgs}/nixos/modules/testing/test-instrumentation.nix";
  autoFormatRootDeviceModule = "${nixpkgs}/nixos/tests/common/auto-format-root-device.nix";
  sourceRoot = self.outPath or (builtins.toString self);
  mkNixAggregate = import ../../../lib/nix/aggregate.nix;

  testInstallerIso =
    (nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          disko
          self
          ;
      };
      modules =
        installerIsoModules
        ++ [
          testInstrumentationModule
          {nixpkgs.pkgs = pkgs;}
        ];
    }).config.system.build.isoImage;

  qemuBinary = "${pkgs.qemu_test}/bin/qemu-system-${pkgs.stdenv.hostPlatform.qemuArch}";
  qemuImg = "${pkgs.qemu_test}/bin/qemu-img";
  ovmfFirmware = pkgs.OVMF.firmware;
  ovmfVariables = pkgs.OVMF.variables;

  vmTestHostModule = pkgs.writeText "darksideos-vm-test-module.nix" ''
    {
      lib,
      modulesPath,
      pkgs,
      ...
    }: {
      imports = [
        (modulesPath + "/testing/test-instrumentation.nix")
      ];

      documentation.enable = lib.mkForce false;
      system.extraDependencies = with pkgs; [
        stdenvNoCC
      ];
      systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
    }
  '';

  commonInstallVirtualisation = {
    virtualisation = {
      cores = 4;
      diskImage = "./target.qcow2";
      diskSize = 40 * 1024;
      memorySize = 4096;
    };
  };
in {
  inherit
    assertions
    autoFormatRootDeviceModule
    commonInstallVirtualisation
    installerIsoModules
    qemuBinary
    qemuImg
    ovmfFirmware
    ovmfVariables
    sourceRoot
    testInstallerIso
    testInstrumentationModule
    vmTestHostModule
    ;

  mkIsoVmTest = {
    name,
    nodes ? {},
    testScript,
  }:
    pkgs.testers.runNixOSTest {
      name = "vm-${name}";
      inherit nodes testScript;
    };

  mkAggregate = args:
    mkNixAggregate (
      args
      // {
        inherit pkgs;
        severity = args.severity or "critical";
        rationale = args.rationale or "All ISO VM child tests must pass for the runtime layer to be trusted.";
      }
    );
}
