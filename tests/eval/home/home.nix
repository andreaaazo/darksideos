# Eval tests for shared-modules/home/home.nix
# Verifies Home Manager integration settings.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.hmModule];
    modules = [
      ../../../shared-modules/home/home.nix
      # Stub: define the andrea user so home-manager can resolve homeDirectory
      {
        users.users.andrea = {
          isNormalUser = true;
          home = "/home/andrea";
        };
      }
    ];
  };

  assertions = [
    (testLib.assertEnabled {
      id = "home-001";
      name = "useGlobalPkgs enabled";
      inherit config;
      path = [
        "home-manager"
        "useGlobalPkgs"
      ];
      severity = "high";
      rationale = "Uses system nixpkgs for faster builds and no version mismatch";
    })

    (testLib.assertEnabled {
      id = "home-002";
      name = "useUserPackages enabled";
      inherit config;
      path = [
        "home-manager"
        "useUserPackages"
      ];
      severity = "high";
      rationale = "Installs to /etc/profiles/per-user, works better with impermanence";
    })

    (testLib.assertEqual {
      id = "home-003";
      name = "andrea username configured";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "home"
        "username"
      ];
      expected = "andrea";
      severity = "high";
      rationale = "Home Manager needs correct username for dotfile placement";
    })

    (testLib.assertEqual {
      id = "home-004";
      name = "andrea home directory configured";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "home"
        "homeDirectory"
      ];
      expected = "/home/andrea";
      severity = "high";
      rationale = "Home Manager needs correct path for symlinks";
    })
  ];
in
  pkgs.runCommand "eval-home-home" {} (
    testLib.mkCheckScript {
      name = "home/home";
      assertionResults = assertions;
    }
  )
