# ISO VM tests entry point.
{
  pkgs,
  lib,
  nixpkgs,
  disko,
  self,
  system,
}: let
  vmLib = import ./lib {
    inherit
      pkgs
      lib
      nixpkgs
      disko
      self
      system
      ;
  };

  smokeTests = import ./smoke {inherit vmLib;};
  installTests = import ./install {inherit vmLib;};

  vmTests = {
    iso-check-vm-smoke = vmLib.mkAggregate {
      name = "iso-check-vm-smoke";
      tests = builtins.attrValues smokeTests;
    };

    iso-check-vm-install = vmLib.mkAggregate {
      name = "iso-check-vm-install";
      tests = builtins.attrValues installTests;
    };
  };
in
  smokeTests
  // installTests
  // vmTests
  // {
    iso-check-vm = vmLib.mkAggregate {
      name = "iso-check-vm";
      tests = builtins.attrValues vmTests;
    };
  }
