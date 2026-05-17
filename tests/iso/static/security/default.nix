{
  pkgs,
  self,
  mkAggregate,
}: let
  tests = {
    check-iso-secrets = import ./secrets.nix {inherit pkgs self;};
  };
in
  tests
  // {
    iso-check-static-security = mkAggregate {
      inherit pkgs;
      name = "iso-check-static-security";
      tests = builtins.attrValues tests;
    };
  }
