# Eval tests for shared-modules/home/modules/features/screenshot/default.nix via home entrypoint.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.hmModule];
    modules = [
      ../../../../../../../shared-modules/home
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
    (testLib.assertContains {
      id = "home-features-screenshot-001";
      name = "Screenshot keybind is present";
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
      element = "$mainMod SHIFT, S, exec, ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs."wl-clipboard"}/bin/wl-copy";
      severity = "high";
      rationale = "Screenshot feature module must expose deterministic capture binding";
    })

    (testLib.assertAnyContainsStringified {
      id = "home-features-screenshot-002";
      name = "Screenshot feature includes grim package";
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
      rationale = "Screenshot feature imports grim module and should materialize binary in user profile";
    })

    (testLib.assertAnyContainsStringified {
      id = "home-features-screenshot-003";
      name = "Screenshot feature includes slurp package";
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
      rationale = "Screenshot feature imports slurp module and should materialize binary in user profile";
    })

    (testLib.assertAnyContainsStringified {
      id = "home-features-screenshot-004";
      name = "Screenshot feature includes wl-clipboard package";
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
      rationale = "Screenshot feature imports wl-clipboard module and should materialize binary in user profile";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-features-screenshot" {} (
    testLib.mkCheckScript {
      name = "home/modules/features/screenshot";
      assertionResults = assertions;
    }
  )
