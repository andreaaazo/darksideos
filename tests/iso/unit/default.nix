# ISO unit tests entry point.
# These tests source pure shell functions and never require root, Disko, SOPS, NixOS, or VM boot.
{
  pkgs,
  self,
}: let
  mkUnit = import ./lib/mk-shell-unit.nix {
    inherit
      pkgs
      self
      ;
  };

  mkAggregate = import ../../lib/nix/aggregate.nix;

  domainTests = import ./domain {inherit mkUnit;};
  applicationTests = import ./application {inherit mkUnit;};
  presentationTests = import ./presentation {inherit mkUnit;};
  infrastructureTests = import ./infrastructure {inherit mkUnit;};

  leafTests =
    domainTests
    // applicationTests
    // presentationTests
    // infrastructureTests;

  unitTests = {
    iso-check-unit-domain = mkAggregate {
      inherit pkgs;
      name = "iso-check-unit-domain";
      tests = builtins.attrValues domainTests;
    };

    iso-check-unit-application = mkAggregate {
      inherit pkgs;
      name = "iso-check-unit-application";
      tests = builtins.attrValues applicationTests;
    };

    iso-check-unit-presentation = mkAggregate {
      inherit pkgs;
      name = "iso-check-unit-presentation";
      tests = builtins.attrValues presentationTests;
    };

    iso-check-unit-infrastructure = mkAggregate {
      inherit pkgs;
      name = "iso-check-unit-infrastructure";
      tests = builtins.attrValues infrastructureTests;
    };
  };
in
  leafTests
  // unitTests
  // {
    iso-check-unit = mkAggregate {
      inherit pkgs;
      name = "iso-check-unit";
      tests = builtins.attrValues unitTests;
      severity = "critical";
      rationale = "The ISO unit layer must pass before higher installer workflows are meaningful.";
    };
  }
