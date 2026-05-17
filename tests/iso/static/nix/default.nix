{
  pkgs,
  self,
  mkAggregate,
}: let
  tests = {
    check-iso-formatting = import ./formatting.nix {inherit pkgs self;};
    check-iso-nix-static = import ./static.nix {inherit pkgs self;};
  };
in
  tests
  // {
    iso-check-static-nix = mkAggregate {
      inherit pkgs;
      name = "iso-check-static-nix";
      tests = builtins.attrValues tests;
    };
  }
