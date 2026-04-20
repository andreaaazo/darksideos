# Eval tests for shared-modules/home/modules/hyprpicker/default.nix via home/home.nix entrypoint.
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
      id = "home-hyprpicker-001";
      name = "Hyprpicker package is in andrea profile";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "home"
        "packages"
      ];
      substring = "hyprpicker";
      severity = "high";
      rationale = "Standalone hyprpicker module should materialize color-picker binary in user profile";
    })

    (testLib.assertContains {
      id = "home-hyprpicker-002";
      name = "Hyprpicker keybind is present";
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
      element = "$mainMod SHIFT, P, exec, ${pkgs.hyprpicker}/bin/hyprpicker -a";
      severity = "high";
      rationale = "Hyprpicker module should wire deterministic color-pick launcher binding";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-hyprpicker" {} (
    testLib.mkCheckScript {
      name = "home/modules/hyprpicker";
      assertionResults = assertions;
    }
  )
