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
  ];
in
  pkgs.runCommand "eval-hardware-bluetooth" {} (
    testLib.mkCheckScript {
      name = "hardware/bluetooth";
      assertionResults = assertions;
    }
  )
