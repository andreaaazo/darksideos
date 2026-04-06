# Eval tests for shared-modules/graphics/hyprland.nix
# Verifies Hyprland compositor and Wayland session setup.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../shared-modules/graphics/hyprland.nix
    ];
  };

  assertions = [
    (testLib.assertEnabled {
      id = "hyprland-001";
      name = "Hyprland compositor enabled";
      inherit config;
      path = [
        "programs"
        "hyprland"
        "enable"
      ];
      severity = "critical";
      rationale = "Hyprland is the primary Wayland compositor";
    })

    (testLib.assertDisabled {
      id = "hyprland-002";
      name = "XWayland disabled";
      inherit config;
      path = [
        "programs"
        "hyprland"
        "xwayland"
        "enable"
      ];
      severity = "high";
      rationale = "XWayland disabled for pure Wayland environment";
    })

    (testLib.assertEnabled {
      id = "hyprland-003";
      name = "PolicyKit enabled";
      inherit config;
      path = [
        "security"
        "polkit"
        "enable"
      ];
      severity = "critical";
      rationale = "Required for input devices, GPU access without root";
    })

    (testLib.assertEqual {
      id = "hyprland-004";
      name = "XDG_SESSION_TYPE is wayland";
      inherit config;
      path = [
        "environment"
        "sessionVariables"
        "XDG_SESSION_TYPE"
      ];
      expected = "wayland";
      severity = "high";
      rationale = "Apps need to know session type for correct rendering";
    })

    (testLib.assertEqual {
      id = "hyprland-005";
      name = "XDG_CURRENT_DESKTOP is Hyprland";
      inherit config;
      path = [
        "environment"
        "sessionVariables"
        "XDG_CURRENT_DESKTOP"
      ];
      expected = "Hyprland";
      severity = "high";
      rationale = "Portal backend selection depends on desktop name";
    })
  ];
in
  pkgs.runCommand "eval-graphics-hyprland" {} (
    testLib.mkCheckScript {
      name = "graphics/hyprland";
      assertionResults = assertions;
    }
  )
