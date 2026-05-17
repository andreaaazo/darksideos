{
  pkgs,
  testLib,
  mkAggregate,
}: let
  tests = {
    eval-iso-configuration = import ./configuration.nix {inherit testLib;};
    eval-iso-metadata = import ./metadata.nix {inherit testLib;};
    eval-iso-configuration-installer-module = import ./installer-module.nix {inherit testLib;};
    eval-iso-configuration-hostname = import ./hostname.nix {inherit testLib;};
  };
in
  tests
  // {
    iso-check-eval-configuration = mkAggregate {
      inherit pkgs;
      name = "iso-check-eval-configuration";
      tests = builtins.attrValues tests;
    };
  }
