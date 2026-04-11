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

    (testLib.assertEqual {
      id = "hyprland-006";
      name = "NIXOS_OZONE_WL is enabled";
      inherit config;
      path = [
        "environment"
        "sessionVariables"
        "NIXOS_OZONE_WL"
      ];
      expected = "1";
      severity = "high";
      rationale = "Chromium/Electron must use native Wayland path";
    })

    (testLib.assertEqual {
      id = "hyprland-007";
      name = "MOZ_ENABLE_WAYLAND is enabled";
      inherit config;
      path = [
        "environment"
        "sessionVariables"
        "MOZ_ENABLE_WAYLAND"
      ];
      expected = "1";
      severity = "high";
      rationale = "Firefox should prefer native Wayland backend";
    })

    (testLib.assertEnabled {
      id = "hyprland-008";
      name = "UWSM mode enabled";
      inherit config;
      path = [
        "programs"
        "hyprland"
        "withUWSM"
      ];
      severity = "high";
      rationale = "Shared baseline should use modern Hyprland session lifecycle";
    })

    (testLib.assertDisabled {
      id = "hyprland-009";
      name = "Hyprland systemd PATH patch disabled";
      inherit config;
      path = [
        "programs"
        "hyprland"
        "systemd"
        "setPath"
        "enable"
      ];
      severity = "medium";
      rationale = "Keep environment minimal and avoid PATH mutation helper";
    })

    (testLib.assertStringContains {
      id = "hyprland-010";
      name = "Hyprland package explicitly selected";
      inherit config;
      path = [
        "programs"
        "hyprland"
        "package"
        "outPath"
      ];
      substring = "hyprland-";
      severity = "medium";
      rationale = "Package source must be explicitly pinned in shared module";
    })

    (testLib.assertStringContains {
      id = "hyprland-011";
      name = "Hyprland portal package explicitly selected";
      inherit config;
      path = [
        "programs"
        "hyprland"
        "portalPackage"
        "outPath"
      ];
      substring = "xdg-desktop-portal-hyprland-";
      severity = "medium";
      rationale = "Portal backend package must be explicit and deterministic";
    })
  ];
in
  pkgs.runCommand "eval-graphics-hyprland" {} (
    testLib.mkCheckScript {
      name = "graphics/hyprland";
      assertionResults = assertions;
    }
  )
