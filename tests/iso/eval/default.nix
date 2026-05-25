# ISO eval tests entry point.
# Exposes responsibility-level configuration contracts for the installer ISO.
{
  pkgs,
  lib,
  self,
  system,
}: let
  testLib = import ./lib {
    inherit
      pkgs
      lib
      self
      system
      ;
  };

  mkAggregate = import ../../lib/nix/aggregate.nix;

  configurationTests = import ./configuration {
    inherit
      pkgs
      testLib
      mkAggregate
      ;
  };

  packageTests = import ./package {
    inherit
      pkgs
      testLib
      mkAggregate
      ;
  };

  runtimeTests = import ./runtime {
    inherit
      pkgs
      testLib
      mkAggregate
      ;
  };

  securityTests = import ./security {
    inherit
      pkgs
      testLib
      mkAggregate
      ;
  };

  sourceTests = import ./source {
    inherit
      pkgs
      testLib
      mkAggregate
      ;
  };

  categoryTests = {
    inherit
      (configurationTests)
      iso-check-eval-configuration
      ;
    inherit
      (packageTests)
      iso-check-eval-package
      ;
    inherit
      (runtimeTests)
      iso-check-eval-runtime
      ;
    inherit
      (securityTests)
      iso-check-eval-security
      ;
    inherit
      (sourceTests)
      iso-check-eval-source
      ;
  };

  evalTests =
    configurationTests
    // packageTests
    // runtimeTests
    // securityTests
    // sourceTests;
in
  evalTests
  // {
    iso-check-eval = mkAggregate {
      inherit pkgs;
      name = "iso-check-eval";
      tests = builtins.attrValues categoryTests;
      severity = "critical";
      rationale = "The ISO must evaluate correctly before it can be built or booted.";
    };
  }
