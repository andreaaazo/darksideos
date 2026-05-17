{
  pkgs,
  testLib,
  mkAggregate,
}: let
  tests = {
    eval-iso-package = import ./package.nix {inherit testLib;};
  };
in
  tests
  // {
    iso-check-eval-package = mkAggregate {
      inherit pkgs;
      name = "iso-check-eval-package";
      tests = builtins.attrValues tests;
    };
  }
