# Eval tests for shared-modules/home/modules/grim/default.nix via home/home.nix entrypoint.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.hmModule];
    modules = [
      ../../../../../../shared-modules/home/home.nix
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
      id = "home-grim-001";
      name = "Grim package is in andrea profile";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "home"
        "packages"
      ];
      substring = "grim";
      severity = "high";
      rationale = "Standalone grim module should materialize grim binary in user profile";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-grim" {} (
    testLib.mkCheckScript {
      name = "home/modules/grim";
      assertionResults = assertions;
    }
  )
