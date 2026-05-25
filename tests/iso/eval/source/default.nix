{
  pkgs,
  testLib,
  mkAggregate,
}: let
  tests = {
    eval-iso-source-files = import ./files.nix {inherit testLib;};
    eval-iso-source-readme = import ./readme.nix {inherit testLib;};
  };
in
  tests
  // {
    iso-check-eval-source = mkAggregate {
      inherit pkgs;
      name = "iso-check-eval-source";
      tests = builtins.attrValues tests;
    };
  }
