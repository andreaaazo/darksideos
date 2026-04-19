# Eval integration test for shared-modules/home entrypoint.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.hmModule];
    modules = [
      ../../../shared-modules/home
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
    (testLib.assertEnabled {
      id = "module-home-001";
      name = "home-manager useGlobalPkgs enabled";
      inherit config;
      path = ["home-manager" "useGlobalPkgs"];
      severity = "high";
      rationale = "Home integration should keep shared nixpkgs source deterministic.";
    })
    (testLib.assertEnabled {
      id = "module-home-002";
      name = "home-manager useUserPackages enabled";
      inherit config;
      path = ["home-manager" "useUserPackages"];
      severity = "high";
      rationale = "Home integration should materialize user profile declaratively.";
    })
    (testLib.assertEnabled {
      id = "module-home-003";
      name = "home-manager user andrea enabled";
      inherit config;
      path = ["home-manager" "users" "andrea" "programs" "home-manager" "enable"];
      severity = "high";
      rationale = "Home integration should keep explicit Home Manager activation.";
    })
  ];
in
  pkgs.runCommand "eval-module-home" {} (
    testLib.mkCheckScript {
      name = "module/home";
      assertionResults = assertions;
    }
  )
