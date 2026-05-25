{
  pkgs,
  self,
  mkAggregate,
}: let
  tests = {
    check-iso-json-schema = import ./json-schema.nix {inherit pkgs self;};
    check-iso-schema-roundtrip = import ./roundtrip.nix {inherit pkgs self;};
  };
in
  tests
  // {
    iso-check-static-schema = mkAggregate {
      inherit pkgs;
      name = "iso-check-static-schema";
      tests = builtins.attrValues tests;
    };
  }
