# Eval tests for shared-modules/hardware/cpu-intel.nix
# Verifies Intel CPU baseline configuration.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../shared-modules/hardware/cpu-intel.nix
    ];
  };

  assertions = [
    (testLib.assertEnabled {
      id = "cpu-intel-001";
      name = "Intel microcode updates enabled";
      inherit config;
      path = [
        "hardware"
        "cpu"
        "intel"
        "updateMicrocode"
      ];
      severity = "critical";
      rationale = "Patches CPU bugs and security vulnerabilities (Spectre, Meltdown)";
    })

    (testLib.assertEnabled {
      id = "cpu-intel-002";
      name = "Redistributable firmware enabled";
      inherit config;
      path = [
        "hardware"
        "enableRedistributableFirmware"
      ];
      severity = "high";
      rationale = "Required for WiFi, Bluetooth, and peripheral firmware";
    })

    (testLib.assertContains {
      id = "cpu-intel-003";
      name = "KVM-Intel kernel module loaded";
      inherit config;
      path = [
        "boot"
        "kernelModules"
      ];
      element = "kvm-intel";
      severity = "high";
      rationale = "Required for KVM/QEMU virtualization";
    })
  ];
in
  pkgs.runCommand "eval-hardware-cpu-intel" {} (
    testLib.mkCheckScript {
      name = "hardware/cpu-intel";
      assertionResults = assertions;
    }
  )
