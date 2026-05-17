# ISO static checks entry point.
# Exposes responsibility-level checks for the installer ISO vertical slice.
{
  pkgs,
  self,
  system,
}: let
  mkAggregate = import ../../lib/nix/aggregate.nix;

  bashChecks = import ./bash {
    inherit
      pkgs
      self
      mkAggregate
      ;
  };

  nixChecks = import ./nix {
    inherit
      pkgs
      self
      mkAggregate
      ;
  };

  docsChecks = import ./docs {
    inherit
      pkgs
      self
      mkAggregate
      ;
  };

  securityChecks = import ./security {
    inherit
      pkgs
      self
      mkAggregate
      ;
  };

  schemaChecks = import ./schema {
    inherit
      pkgs
      self
      mkAggregate
      ;
  };

  categoryChecks = {
    inherit
      (bashChecks)
      iso-check-static-bash
      ;
    inherit
      (nixChecks)
      iso-check-static-nix
      ;
    inherit
      (docsChecks)
      iso-check-static-docs
      ;
    inherit
      (securityChecks)
      iso-check-static-security
      ;
    inherit
      (schemaChecks)
      iso-check-static-schema
      ;
  };

  checks =
    bashChecks
    // nixChecks
    // docsChecks
    // securityChecks
    // schemaChecks;
in
  checks
  // {
    iso-check-static = mkAggregate {
      inherit pkgs;
      name = "iso-check-static";
      tests = builtins.attrValues categoryChecks;
      severity = "critical";
      rationale = "The ISO static gate must pass before unit, integration, eval, or VM tests can be trusted.";
    };
  }
