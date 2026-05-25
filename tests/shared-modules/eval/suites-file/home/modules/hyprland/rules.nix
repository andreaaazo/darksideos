# Eval tests for shared-modules/home/modules/hyprland/rules.nix.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.hmModule];
    modules = [
      ../../../../../../../shared-modules/home/home.nix
      {
        nixpkgs.config.allowUnfree = true;
        users.users.andrea = {
          isNormalUser = true;
          home = "/home/andrea";
        };
      }
    ];
  };

  windowrulev2Path = [
    "home-manager"
    "users"
    "andrea"
    "wayland"
    "windowManager"
    "hyprland"
    "settings"
    "windowrulev2"
  ];

  assertions = [
    (testLib.assertContains {
      id = "home-hyprland-rules-spotify-opacity";
      name = "Spotify opacity override rule is declared";
      inherit config;
      path = windowrulev2Path;
      element = "opacity 0.80 override 0.80 override, match:^(spotify)$";
      severity = "medium";
      rationale = "Spotify visual policy must remain explicit in the rule contract.";
    })

    (testLib.assertContains {
      id = "home-hyprland-rules-kitty-opacity";
      name = "Kitty opacity override rule is declared";
      inherit config;
      path = windowrulev2Path;
      element = "opacity 1.00 override 1.00 override, class:^(kitty)$";
      severity = "medium";
      rationale = "Terminal must render fully opaque so kitty's own background control wins.";
    })

    (testLib.assertContains {
      id = "home-hyprland-rules-fullscreen-noshadow";
      name = "Fullscreen windows skip shadow rendering";
      inherit config;
      path = windowrulev2Path;
      element = "noshadow, fullscreen:1";
      severity = "low";
      rationale = "Shadow on fullscreen windows wastes GPU cycles with no visual benefit.";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-hyprland-rules" {} (
    testLib.mkCheckScript {
      name = "home/modules/hyprland/rules";
      assertionResults = assertions;
    }
  )
