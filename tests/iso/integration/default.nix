# ISO integration tests entry point.
# These tests run the real installer use case with destructive adapters replaced by stubs.
{
  pkgs,
  self,
}: let
  mkIntegration = import ./lib/mk-shell-integration.nix {
    inherit
      pkgs
      self
      ;
  };

  mkAggregate = import ../../lib/nix/aggregate.nix;

  createNewHostTests = import ./create-new-host {inherit mkIntegration;};

  integrationTests = {
    iso-check-integration-create-new-host = mkAggregate {
      inherit pkgs;
      name = "iso-check-integration-create-new-host";
      tests = builtins.attrValues createNewHostTests;
    };
  };
in
  createNewHostTests
  // integrationTests
  // {
    iso-check-integration = mkAggregate {
      inherit pkgs;
      name = "iso-check-integration";
      tests = builtins.attrValues integrationTests;
      severity = "critical";
      rationale = "The installer workflow contract must pass before destructive VM installation tests run.";
    };
  }
