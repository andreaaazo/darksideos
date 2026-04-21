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
    (testLib.assertContains {
      id = "module-home-004";
      name = "hyprland window rules use current syntax";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "settings"
        "windowrule"
      ];
      element = "opacity 0.80 override 0.80 override, match:class ^(spotify)$";
      severity = "medium";
      rationale = "Home integration should keep generated Hyprland rules on current syntax.";
    })
    (testLib.assertEnabled {
      id = "module-home-005";
      name = "git program module is enabled";
      inherit config;
      path = ["home-manager" "users" "andrea" "programs" "git" "enable"];
      severity = "medium";
      rationale = "Home integration should import the dedicated Git module rather than relying on loose packages.";
    })
    (testLib.assertString {
      id = "module-home-006";
      name = "git signing key uses standard secret path";
      inherit config;
      path = ["home-manager" "users" "andrea" "programs" "git" "settings" "user" "signingKey"];
      expected = "/run/secrets/andrea-git-ssh-key";
      severity = "medium";
      rationale = "Home integration should use the shared Git SSH secret-name contract.";
    })
    (testLib.assertContains {
      id = "module-home-007";
      name = "git ssh auth key uses standard secret path";
      inherit config;
      path = ["home-manager" "users" "andrea" "programs" "ssh" "matchBlocks" "github.com" "data" "identityFile"];
      element = "/run/secrets/andrea-git-ssh-key";
      severity = "medium";
      rationale = "Home integration should reuse the shared Git SSH secret-name contract.";
    })
  ];
in
  pkgs.runCommand "eval-module-home" {} (
    testLib.mkCheckScript {
      name = "module/home";
      assertionResults = assertions;
    }
  )
