# Eval integration test for shared-modules/graphics entrypoint.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../shared-modules/graphics
    ];
  };
  assertions = [
    (testLib.assertEnabled {
      id = "module-graphics-001";
      name = "hyprland enabled";
      inherit config;
      path = ["programs" "hyprland" "enable"];
      severity = "critical";
      rationale = "Graphics integration must keep Hyprland enabled.";
    })
    (testLib.assertDisabled {
      id = "module-graphics-002";
      name = "xwayland disabled";
      inherit config;
      path = ["programs" "hyprland" "xwayland" "enable"];
      severity = "high";
      rationale = "Graphics integration must preserve pure Wayland policy.";
    })
    (testLib.assertEnabled {
      id = "module-graphics-003";
      name = "portal enabled";
      inherit config;
      path = ["xdg" "portal" "enable"];
      severity = "high";
      rationale = "Graphics integration must expose desktop portals.";
    })
    (testLib.assertEqual {
      id = "module-graphics-004";
      name = "portal default routing is hyprland then gtk";
      inherit config;
      path = ["xdg" "portal" "config" "common" "default"];
      expected = "hyprland;gtk";
      severity = "high";
      rationale = "Graphics integration must keep deterministic portal routing.";
    })
  ];
in
  pkgs.runCommand "eval-module-graphics" {} (
    testLib.mkCheckScript {
      name = "module/graphics";
      assertionResults = assertions;
    }
  )
