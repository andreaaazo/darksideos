{
  pkgs,
  testLib,
  mkAggregate,
}: let
  tests = {
    eval-iso-entrypoint = import ./entrypoint.nix {inherit testLib;};
    eval-iso-runtime-inputs = import ./inputs.nix {inherit testLib;};
    eval-iso-runtime-installer-command = import ./installer-command.nix {inherit testLib;};
  };
in
  tests
  // {
    iso-check-eval-runtime = mkAggregate {
      inherit pkgs;
      name = "iso-check-eval-runtime";
      tests = builtins.attrValues tests;
    };
  }
