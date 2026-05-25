# Eval tests for shared-modules/home/modules/hyprland/input.nix.
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

  inputPath = [
    "home-manager"
    "users"
    "andrea"
    "wayland"
    "windowManager"
    "hyprland"
    "settings"
    "input"
  ];

  assertions = [
    (testLib.assertEqual {
      id = "home-hyprland-input-follow-mouse";
      name = "follow_mouse is enabled (mode 1)";
      inherit config;
      path = inputPath ++ ["follow_mouse"];
      expected = 1;
      severity = "high";
      rationale = "Focus-follows-mouse is the documented input policy.";
    })

    (testLib.assertEqual {
      id = "home-hyprland-input-sensitivity";
      name = "Pointer sensitivity is 1.5";
      inherit config;
      path = inputPath ++ ["sensitivity"];
      expected = 1.5;
      severity = "medium";
      rationale = "Sensitivity is part of the pointer ergonomics contract.";
    })

    (testLib.assertEqual {
      id = "home-hyprland-input-accel-profile";
      name = "Pointer acceleration profile is flat";
      inherit config;
      path = inputPath ++ ["accel_profile"];
      expected = "flat";
      severity = "high";
      rationale = "Flat acceleration is the documented baseline; adaptive would change muscle-memory throws.";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-hyprland-input" {} (
    testLib.mkCheckScript {
      name = "home/modules/hyprland/input";
      assertionResults = assertions;
    }
  )
