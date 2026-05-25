# Eval tests for shared-modules/home/modules/hyprland/theme.nix.
# Covers visual contract (gaps, borders, opacity, blur, shadow).
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

  settingsPath = [
    "home-manager"
    "users"
    "andrea"
    "wayland"
    "windowManager"
    "hyprland"
    "settings"
  ];

  assertions = [
    (testLib.assertEqual {
      id = "home-hyprland-theme-gaps-in";
      name = "Hyprland inner gaps are zero";
      inherit config;
      path = settingsPath ++ ["general" "gaps_in"];
      expected = 0;
      severity = "medium";
      rationale = "Dense edge-aligned tiling is part of the declared visual baseline.";
    })

    (testLib.assertEqual {
      id = "home-hyprland-theme-gaps-out";
      name = "Hyprland outer gaps are 16";
      inherit config;
      path = settingsPath ++ ["general" "gaps_out"];
      expected = 16;
      severity = "medium";
      rationale = "Outer padding contract must remain stable; window-move wrapper math depends on it.";
    })

    (testLib.assertEqual {
      id = "home-hyprland-theme-border-size";
      name = "Hyprland border size is 3";
      inherit config;
      path = settingsPath ++ ["general" "border_size"];
      expected = 3;
      severity = "low";
      rationale = "Border thickness is part of the declared visual contract.";
    })

    (testLib.assertEqual {
      id = "home-hyprland-theme-layout";
      name = "Hyprland default layout is dwindle";
      inherit config;
      path = settingsPath ++ ["general" "layout"];
      expected = "dwindle";
      severity = "high";
      rationale = "Tiling algorithm is the foundation users build muscle memory on.";
    })

    (testLib.assertStringContains {
      id = "home-hyprland-theme-active-border";
      name = "Active border uses the declared purple gradient";
      inherit config;
      # `col.active_border` is nested in Nix: settings.general.col.active_border.
      path = settingsPath ++ ["general" "col" "active_border"];
      substring = "rgba(7d00e0ee)";
      severity = "low";
      rationale = "Brand color of focused window border is part of the visual contract.";
    })

    (testLib.assertEqual {
      id = "home-hyprland-theme-rounding";
      name = "Hyprland window corner rounding is 8";
      inherit config;
      path = settingsPath ++ ["decoration" "rounding"];
      expected = 8;
      severity = "low";
      rationale = "Window corner rounding is part of the declared visual contract.";
    })

    (testLib.assertEqual {
      id = "home-hyprland-theme-rounding-power";
      name = "Hyprland window rounding power is 4";
      inherit config;
      path = settingsPath ++ ["decoration" "rounding_power"];
      expected = 4;
      severity = "low";
      rationale = "Rounding curve is part of the visual contract.";
    })

    (testLib.assertEqual {
      id = "home-hyprland-theme-active-opacity";
      name = "Active window opacity is 1";
      inherit config;
      path = settingsPath ++ ["decoration" "active_opacity"];
      expected = 1;
      severity = "medium";
      rationale = "Focused window must remain fully opaque for legibility.";
    })

    (testLib.assertEqual {
      id = "home-hyprland-theme-inactive-opacity";
      name = "Inactive window opacity is 0.88";
      inherit config;
      path = settingsPath ++ ["decoration" "inactive_opacity"];
      expected = 0.88;
      severity = "medium";
      rationale = "Inactive translucency is part of the focus-cue contract.";
    })

    (testLib.assertEnabled {
      id = "home-hyprland-theme-shadow-enabled";
      name = "Window shadow rendering is enabled";
      inherit config;
      path = settingsPath ++ ["decoration" "shadow" "enabled"];
      severity = "low";
      rationale = "Shadow rendering is part of the visual baseline.";
    })

    (testLib.assertEqual {
      id = "home-hyprland-theme-shadow-range";
      name = "Window shadow range is 16";
      inherit config;
      path = settingsPath ++ ["decoration" "shadow" "range"];
      expected = 16;
      severity = "low";
      rationale = "Shadow spread is part of the visual contract.";
    })

    (testLib.assertEnabled {
      id = "home-hyprland-theme-blur-enabled";
      name = "Background blur is enabled";
      inherit config;
      path = settingsPath ++ ["decoration" "blur" "enabled"];
      severity = "medium";
      rationale = "Blur is part of the depth-perception contract for the desktop.";
    })

    (testLib.assertEqual {
      id = "home-hyprland-theme-blur-size";
      name = "Background blur size is 8";
      inherit config;
      path = settingsPath ++ ["decoration" "blur" "size"];
      expected = 8;
      severity = "low";
      rationale = "Blur radius is part of the visual contract.";
    })

    (testLib.assertEqual {
      id = "home-hyprland-theme-blur-passes";
      name = "Background blur passes is 3";
      inherit config;
      path = settingsPath ++ ["decoration" "blur" "passes"];
      expected = 3;
      severity = "low";
      rationale = "Multi-pass blur prevents banding artifacts.";
    })

    (testLib.assertEnabled {
      id = "home-hyprland-theme-blur-new-optimizations";
      name = "Blur uses new optimization pipeline";
      inherit config;
      path = settingsPath ++ ["decoration" "blur" "new_optimizations"];
      severity = "low";
      rationale = "Newer blur pipeline reduces GPU cost for the same visual quality.";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-hyprland-theme" {} (
    testLib.mkCheckScript {
      name = "home/modules/hyprland/theme";
      assertionResults = assertions;
    }
  )
