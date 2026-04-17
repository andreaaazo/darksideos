# Eval tests for shared-modules/hardware/cpu-amd.nix
# Verifies AMD-specific CPU baseline configuration.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../../shared-modules/hardware/cpu-amd.nix
    ];
  };

  assertions = [
    (testLib.assertEnabled {
      id = "cpu-amd-001";
      name = "AMD microcode updates enabled";
      inherit config;
      path = [
        "hardware"
        "cpu"
        "amd"
        "updateMicrocode"
      ];
      severity = "critical";
      rationale = "Patches AMD CPU bugs and security vulnerabilities.";
    })

    (testLib.assertEnabled {
      id = "cpu-amd-002";
      name = "Redistributable firmware enabled";
      inherit config;
      path = [
        "hardware"
        "enableRedistributableFirmware"
      ];
      severity = "high";
      rationale = "Required for firmware-backed peripherals.";
    })

    (testLib.assertContains {
      id = "cpu-amd-003";
      name = "KVM-AMD kernel module loaded";
      inherit config;
      path = [
        "boot"
        "kernelModules"
      ];
      element = "kvm-amd";
      severity = "high";
      rationale = "AMD virtualization baseline requires kvm-amd.";
    })

    (testLib.assertContains {
      id = "cpu-amd-004";
      name = "AMD IOMMU enabled via kernel parameter";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "amd_iommu=on";
      severity = "high";
      rationale = "Enables AMD DMA remapping isolation.";
    })

    (testLib.assertStringContains {
      id = "cpu-amd-005";
      name = "kvm_amd nested virtualization is explicitly enabled";
      inherit config;
      path = [
        "boot"
        "extraModprobeConfig"
      ];
      substring = "options kvm_amd nested=1";
      severity = "medium";
      rationale = "Makes AMD KVM nested behavior explicit.";
    })

    (testLib.assertStringContains {
      id = "cpu-amd-006";
      name = "kvm_amd NPT is explicitly enabled";
      inherit config;
      path = [
        "boot"
        "extraModprobeConfig"
      ];
      substring = "options kvm_amd npt=1";
      severity = "medium";
      rationale = "Pins AMD NPT virtualization behavior.";
    })

    (testLib.assertStringContains {
      id = "cpu-amd-007";
      name = "kvm_amd AVIC is explicitly enabled";
      inherit config;
      path = [
        "boot"
        "extraModprobeConfig"
      ];
      substring = "options kvm_amd avic=1";
      severity = "medium";
      rationale = "Pins AMD AVIC virtualization behavior.";
    })
  ];
in
  pkgs.runCommand "eval-hardware-cpu-amd" {} (
    testLib.mkCheckScript {
      name = "hardware/cpu-amd";
      assertionResults = assertions;
    }
  )
