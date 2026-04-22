# Eval tests for shared-modules/home/modules/slurp/default.nix via home entrypoint.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.hmModule];
    modules = [
      ../../../../../../shared-modules/home
      {
        nixpkgs.config.allowUnfree = true;
        users.users.andrea = {
          isNormalUser = true;
          home = "/home/andrea";
        };
      }
    ];
  };

  assertions = [
    (testLib.assertAnyContainsStringified {
      id = "home-slurp-001";
      name = "Slurp package is in andrea profile";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "home"
        "packages"
      ];
      substring = "slurp";
      severity = "high";
      rationale = "Standalone slurp module should materialize slurp binary in user profile";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-slurp" {} (
    testLib.mkCheckScript {
      name = "home/modules/slurp";
      assertionResults = assertions;
    }
  )
