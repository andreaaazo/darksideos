# Eval tests for shared-modules/home/modules/kitty/default.nix via home entrypoint.
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
      id = "home-kitty-001";
      name = "Kitty package is in andrea profile";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "home"
        "packages"
      ];
      substring = "kitty";
      severity = "high";
      rationale = "Standalone kitty module should materialize terminal binary in user profile";
    })

    (testLib.assertContains {
      id = "home-kitty-002";
      name = "Kitty keybind is present";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "settings"
        "bind"
      ];
      element = "$mainMod, T, exec, ${pkgs.kitty}/bin/kitty";
      severity = "high";
      rationale = "Kitty module should wire deterministic terminal launcher binding";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-kitty" {} (
    testLib.mkCheckScript {
      name = "home/modules/kitty";
      assertionResults = assertions;
    }
  )
