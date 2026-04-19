# Eval tests for shared-modules/hardware/cpu-intel.nix
# Verifies Intel-specific CPU baseline configuration.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../../shared-modules/hardware/cpu-intel.nix
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
      rationale = "Patches Intel CPU bugs and security vulnerabilities.";
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
      rationale = "Required for firmware-backed peripherals.";
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
      rationale = "Intel virtualization baseline requires kvm-intel.";
    })

    (testLib.assertContains {
      id = "cpu-intel-004";
      name = "Intel IOMMU enabled via kernel parameter";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "intel_iommu=on";
      severity = "high";
      rationale = "Enables Intel DMA remapping isolation.";
    })

    (testLib.assertContains {
      id = "cpu-intel-005";
      name = "TSX disabled";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "tsx=off";
      severity = "high";
      rationale = "Reduces Intel TSX-related side-channel attack surface.";
    })

    (testLib.assertStringContains {
      id = "cpu-intel-006";
      name = "kvm_intel nested virtualization is explicitly enabled";
      inherit config;
      path = [
        "boot"
        "extraModprobeConfig"
      ];
      substring = "options kvm_intel nested=1";
      severity = "medium";
      rationale = "Makes Intel KVM nested behavior explicit.";
    })

    (testLib.assertStringContains {
      id = "cpu-intel-007";
      name = "kvm_intel EPT is explicitly enabled";
      inherit config;
      path = [
        "boot"
        "extraModprobeConfig"
      ];
      substring = "options kvm_intel ept=1";
      severity = "medium";
      rationale = "Pins Intel EPT virtualization behavior.";
    })

    (testLib.assertStringContains {
      id = "cpu-intel-008";
      name = "kvm_intel APICv is explicitly enabled";
      inherit config;
      path = [
        "boot"
        "extraModprobeConfig"
      ];
      substring = "options kvm_intel enable_apicv=1";
      severity = "medium";
      rationale = "Pins Intel APICv virtualization behavior.";
    })
  ];
in
  pkgs.runCommand "eval-hardware-cpu-intel" {} (
    testLib.mkCheckScript {
      name = "hardware/cpu-intel";
      assertionResults = assertions;
    }
  )
