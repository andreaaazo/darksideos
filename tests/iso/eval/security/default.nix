{
  pkgs,
  testLib,
  mkAggregate,
}: let
  tests = {
    eval-iso-security = import ./security.nix {inherit testLib;};
    eval-iso-security-services = import ./services.nix {inherit testLib;};
  };
in
  tests
  // {
    iso-check-eval-security = mkAggregate {
      inherit pkgs;
      name = "iso-check-eval-security";
      tests = builtins.attrValues tests;
    };
  }
