# Eval tests for shared-modules/graphics/portal.nix
# Verifies XDG Desktop Portals for sandboxed screen capture, file dialogs.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../../shared-modules/graphics/portal.nix
    ];
  };

  assertions = [
    (testLib.assertEnabled {
      id = "portal-001";
      name = "XDG portal enabled";
      inherit config;
      path = [
        "xdg"
        "portal"
        "enable"
      ];
      severity = "critical";
      rationale = "Required for sandboxed screen capture, file dialogs, notifications";
    })

    (testLib.assertEnabled {
      id = "portal-002";
      name = "D-Bus service enabled";
      inherit config;
      path = [
        "services"
        "dbus"
        "enable"
      ];
      severity = "critical";
      rationale = "D-Bus required for XDG portals, polkit, NetworkManager";
    })

    (testLib.assertEnabled {
      id = "portal-003";
      name = "xdg-open uses portal path";
      inherit config;
      path = [
        "xdg"
        "portal"
        "xdgOpenUsePortal"
      ];
      severity = "high";
      rationale = "forces deterministic portal-mediated open behavior";
    })

    (testLib.assertContains {
      id = "portal-005";
      name = "GTK portal backend installed";
      inherit config;
      path = [
        "xdg"
        "portal"
        "extraPortals"
      ];
      element = pkgs.xdg-desktop-portal-gtk;
      severity = "high";
      rationale = "GTK backend is required for file chooser and settings interfaces";
    })

    (testLib.assertEqual {
      id = "portal-006";
      name = "default portal priority is hyprland then gtk";
      inherit config;
      path = [
        "xdg"
        "portal"
        "config"
        "common"
        "default"
      ];
      expected = "hyprland;gtk";
      severity = "high";
      rationale = "Default portal routing must be explicit and deterministic";
    })

    (testLib.assertEqual {
      id = "portal-007";
      name = "ScreenCast routed to hyprland";
      inherit config;
      path = [
        "xdg"
        "portal"
        "config"
        "common"
        "org.freedesktop.impl.portal.ScreenCast"
      ];
      expected = "hyprland";
      severity = "high";
      rationale = "Screen capture path must use Hyprland-native backend";
    })

    (testLib.assertEqual {
      id = "portal-008";
      name = "Screenshot routed to hyprland";
      inherit config;
      path = [
        "xdg"
        "portal"
        "config"
        "common"
        "org.freedesktop.impl.portal.Screenshot"
      ];
      expected = "hyprland";
      severity = "high";
      rationale = "Screenshot path must use Hyprland-native backend";
    })

    (testLib.assertEqual {
      id = "portal-009";
      name = "RemoteDesktop routed to hyprland";
      inherit config;
      path = [
        "xdg"
        "portal"
        "config"
        "common"
        "org.freedesktop.impl.portal.RemoteDesktop"
      ];
      expected = "hyprland";
      severity = "high";
      rationale = "Remote desktop path must use Hyprland-native backend";
    })

    (testLib.assertEqual {
      id = "portal-010";
      name = "FileChooser routed to gtk";
      inherit config;
      path = [
        "xdg"
        "portal"
        "config"
        "common"
        "org.freedesktop.impl.portal.FileChooser"
      ];
      expected = "gtk";
      severity = "high";
      rationale = "File chooser interface should use GTK backend";
    })

    (testLib.assertEqual {
      id = "portal-011";
      name = "Settings routed to gtk";
      inherit config;
      path = [
        "xdg"
        "portal"
        "config"
        "common"
        "org.freedesktop.impl.portal.Settings"
      ];
      expected = "gtk";
      severity = "high";
      rationale = "Settings interface should use GTK backend";
    })
  ];
in
  pkgs.runCommand "eval-graphics-portal" {} (
    testLib.mkCheckScript {
      name = "graphics/portal";
      assertionResults = assertions;
    }
  )
