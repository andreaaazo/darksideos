# Eval tests for shared-modules/core/boot.nix
# Verifies boot security settings and systemd-boot configuration.
{
  pkgs,
  testLib,
}: let
  # Evaluate only the boot module in isolation
  config = testLib.getConfig {
    modules = [
      ../../../shared-modules/core/boot.nix
    ];
  };

  # Define assertions for this module
  assertions = [
    (testLib.assertEnabled {
      id = "boot-001";
      name = "systemd-boot enabled";
      inherit config;
      path = [
        "boot"
        "loader"
        "systemd-boot"
        "enable"
      ];
      severity = "critical";
      rationale = "UEFI bootloader required for system boot";
    })

    (testLib.assertDisabled {
      id = "boot-002";
      name = "bootloader editor disabled";
      inherit config;
      path = [
        "boot"
        "loader"
        "systemd-boot"
        "editor"
      ];
      severity = "critical";
      rationale = "Prevents root shell access via init=/bin/sh kernel parameter";
    })

    (testLib.assertEnabled {
      id = "boot-003";
      name = "EFI variables writable";
      inherit config;
      path = [
        "boot"
        "loader"
        "efi"
        "canTouchEfiVariables"
      ];
      severity = "high";
      rationale = "Required for systemd-boot to register itself in UEFI";
    })

    (testLib.assertEqual {
      id = "boot-004";
      name = "boot generations limited";
      inherit config;
      path = [
        "boot"
        "loader"
        "systemd-boot"
        "configurationLimit"
      ];
      expected = 4;
      severity = "medium";
      rationale = "Prevents /boot from filling up with old generations";
    })
  ];
in
  pkgs.runCommand "eval-core-boot" {} (
    testLib.mkCheckScript {
      name = "core/boot";
      assertionResults = assertions;
    }
  )
