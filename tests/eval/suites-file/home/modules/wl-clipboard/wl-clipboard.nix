# Eval tests for shared-modules/home/modules/wl-clipboard/default.nix via home entrypoint.
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
      id = "home-wl-clipboard-001";
      name = "wl-clipboard package is in andrea profile";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "home"
        "packages"
      ];
      substring = "wl-clipboard";
      severity = "high";
      rationale = "Standalone wl-clipboard module should provide wl-copy/wl-paste tooling";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-wl-clipboard" {} (
    testLib.mkCheckScript {
      name = "home/modules/wl-clipboard";
      assertionResults = assertions;
    }
  )
