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

    (testLib.assertEqual {
      id = "boot-005";
      name = "console log level reduced";
      inherit config;
      path = [
        "boot"
        "consoleLogLevel"
      ];
      expected = 3;
      severity = "medium";
      rationale = "Reduces boot noise and keeps only relevant kernel messages";
    })

    (testLib.assertDisabled {
      id = "boot-006";
      name = "initrd verbose logging disabled";
      inherit config;
      path = [
        "boot"
        "initrd"
        "verbose"
      ];
      severity = "medium";
      rationale = "Avoids verbose initrd logging in normal boot path";
    })

    (testLib.assertContains {
      id = "boot-007";
      name = "quiet kernel param set";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "quiet";
      severity = "medium";
      rationale = "Keeps kernel boot output lean in production-like environments";
    })

    (testLib.assertContains {
      id = "boot-008";
      name = "kernel loglevel capped";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "loglevel=3";
      severity = "medium";
      rationale = "Limits kernel console output to warnings and errors";
    })

    (testLib.assertContains {
      id = "boot-009";
      name = "udev log level capped";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "udev.log_level=3";
      severity = "medium";
      rationale = "Keeps device-init logs focused and less noisy";
    })
  ];
in
  pkgs.runCommand "eval-core-boot" {} (
    testLib.mkCheckScript {
      name = "core/boot";
      assertionResults = assertions;
    }
  )
