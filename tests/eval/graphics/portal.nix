# Eval tests for shared-modules/graphics/portal.nix
# Verifies XDG Desktop Portals for sandboxed screen capture, file dialogs.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../shared-modules/graphics/portal.nix
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
  ];
in
  pkgs.runCommand "eval-graphics-portal" {} (
    testLib.mkCheckScript {
      name = "graphics/portal";
      assertionResults = assertions;
    }
  )
