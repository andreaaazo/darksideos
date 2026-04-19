# Eval tests for shared-modules/home/home.nix
# Verifies Home Manager integration settings.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.hmModule];
    modules = [
      ../../../../shared-modules/home/home.nix
      # Stub: define the andrea user so home-manager can resolve homeDirectory
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

    (testLib.assertDisabled {
      id = "home-005";
      name = "nixpkgs release check disabled for andrea";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "home"
        "enableNixpkgsReleaseCheck"
      ];
      severity = "medium";
      rationale = "Shared baseline keeps activation lean by disabling release mismatch check noise";
    })

    (testLib.assertEnabled {
      id = "home-006";
      name = "Home Manager program enabled for andrea";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "programs"
        "home-manager"
        "enable"
      ];
      severity = "high";
      rationale = "Home Manager CLI should be explicit and reproducible in the user profile";
    })

    (testLib.assertDisabled {
      id = "home-007";
      name = "Home Manager manpages disabled for andrea";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "manual"
        "manpages"
        "enable"
      ];
      severity = "medium";
      rationale = "Shared baseline stays minimal by skipping generated Home Manager manpage payload";
    })
  ];
in
  pkgs.runCommand "eval-home-home" {} (
    testLib.mkCheckScript {
      name = "home/home";
      assertionResults = assertions;
    }
  )
