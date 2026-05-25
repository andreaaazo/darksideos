# Eval tests for shared-modules/home/modules/hyprland/system.nix (misc namespace).
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

  miscPath = [
    "home-manager"
    "users"
    "andrea"
    "wayland"
    "windowManager"
    "hyprland"
    "settings"
    "misc"
  ];

  assertions = [
    (testLib.assertEnabled {
      id = "home-hyprland-system-logo-hidden";
      name = "Hyprland branding logo is hidden";
      inherit config;
      path = miscPath ++ ["disable_hyprland_logo"];
      severity = "low";
      rationale = "Startup branding adds visual noise and should remain disabled.";
    })

    (testLib.assertEnabled {
      id = "home-hyprland-system-splash-hidden";
      name = "Hyprland splash rendering is disabled";
      inherit config;
      path = miscPath ++ ["disable_splash_rendering"];
      severity = "low";
      rationale = "Splash adds wasted startup work for a desktop that already manages wallpaper via hyprpaper.";
    })

    (testLib.assertEqual {
      id = "home-hyprland-system-default-wallpaper-off";
      name = "Hyprland built-in wallpaper override is disabled";
      inherit config;
      path = miscPath ++ ["force_default_wallpaper"];
      expected = 0;
      severity = "medium";
      rationale = "Built-in wallpaper must not override hyprpaper-managed background policy.";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-hyprland-system" {} (
    testLib.mkCheckScript {
      name = "home/modules/hyprland/system";
      assertionResults = assertions;
    }
  )
