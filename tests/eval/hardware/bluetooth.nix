# Eval tests for shared-modules/hardware/bluetooth.nix
# Verifies Bluetooth baseline configuration.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../shared-modules/hardware/bluetooth.nix
    ];
  };

  assertions = [
    (testLib.assertEnabled {
      id = "bluetooth-001";
      name = "Bluetooth enabled";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "enable"
      ];
      severity = "high";
      rationale = "BlueZ stack required for Bluetooth hardware management";
    })

    (testLib.assertDisabled {
      id = "bluetooth-002";
      name = "Bluetooth power on boot disabled";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "powerOnBoot"
      ];
      severity = "medium";
      rationale = "Radio stays off until manually enabled for power saving";
    })

    (testLib.assertDisabled {
      id = "bluetooth-003";
      name = "hsphfpd disabled";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "hsphfpd"
        "enable"
      ];
      severity = "medium";
      rationale = "Shared baseline avoids optional headset prototype daemon";
    })

    (testLib.assertStringContains {
      id = "bluetooth-004";
      name = "BlueZ package explicitly selected";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "package"
        "outPath"
      ];
      substring = "bluez-";
      severity = "medium";
      rationale = "Package source should stay explicit and deterministic";
    })

    (testLib.assertContains {
      id = "bluetooth-005";
      name = "legacy SAP plugin disabled";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "disabledPlugins"
      ];
      element = "sap";
      severity = "medium";
      rationale = "Shared baseline removes legacy SAP plugin footprint";
    })

    (testLib.assertEqual {
      id = "bluetooth-006";
      name = "ControllerMode set to dual";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "settings"
        "General"
        "ControllerMode"
      ];
      expected = "dual";
      severity = "high";
      rationale = "Bluetooth controller mode should be explicit";
    })

    (testLib.assertEqual {
      id = "bluetooth-007";
      name = "Privacy set to device";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "settings"
        "General"
        "Privacy"
      ];
      expected = "device";
      severity = "high";
      rationale = "Controller privacy mode should be explicitly enforced";
    })

    (testLib.assertEqual {
      id = "bluetooth-008";
      name = "JustWorksRepairing set to never";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "settings"
        "General"
        "JustWorksRepairing"
      ];
      expected = "never";
      severity = "high";
      rationale = "Prevents automatic trust repair behavior";
    })

    (testLib.assertEnabled {
      id = "bluetooth-009";
      name = "Experimental mode enabled";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "settings"
        "General"
        "Experimental"
      ];
      severity = "medium";
      rationale = "Enables bleeding-edge BlueZ features in shared baseline";
    })

    (testLib.assertDisabled {
      id = "bluetooth-010";
      name = "AutoEnable policy disabled";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "settings"
        "Policy"
        "AutoEnable"
      ];
      severity = "medium";
      rationale = "Avoids automatic radio activation at daemon startup";
    })

    (testLib.assertEnabled {
      id = "bluetooth-011";
      name = "ClassicBondedOnly enabled for input profile";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "input"
        "General"
        "ClassicBondedOnly"
      ];
      severity = "high";
      rationale = "Input profile should only accept bonded classic devices";
    })

    (testLib.assertDisabled {
      id = "bluetooth-012";
      name = "network DisableSecurity is false";
      inherit config;
      path = [
        "hardware"
        "bluetooth"
        "network"
        "General"
        "DisableSecurity"
      ];
      severity = "high";
      rationale = "Network profile should keep security checks enabled";
    })
  ];
in
  pkgs.runCommand "eval-hardware-bluetooth" {} (
    testLib.mkCheckScript {
      name = "hardware/bluetooth";
      assertionResults = assertions;
    }
  )
