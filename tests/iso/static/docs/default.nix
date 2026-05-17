{
  pkgs,
  self,
  mkAggregate,
}: let
  tests = {
    check-iso-readme = import ./readme.nix {inherit pkgs self;};
  };
in
  tests
  // {
    iso-check-static-docs = mkAggregate {
      inherit pkgs;
      name = "iso-check-static-docs";
      tests = builtins.attrValues tests;
    };
  }
