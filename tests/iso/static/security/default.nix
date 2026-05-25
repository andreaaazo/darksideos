{
  pkgs,
  self,
  mkAggregate,
}: let
  tests = {
    check-iso-secrets = import ./secrets.nix {inherit pkgs self;};
  };
in
  # The CVE scan is intentionally not a Nix derivation: vulnix shells out to
  # `nix path-info`, which needs nix-db access unavailable to the sandbox build
  # user. It runs as a system tool via scripts/iso/check-cve.sh instead.
  tests
  // {
    iso-check-static-security = mkAggregate {
      inherit pkgs;
      name = "iso-check-static-security";
      tests = builtins.attrValues tests;
    };
  }
