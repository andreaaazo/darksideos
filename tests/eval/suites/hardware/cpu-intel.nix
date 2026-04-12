# Eval tests for shared-modules/hardware/cpu-intel.nix
# Verifies Intel CPU baseline configuration.
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
      rationale = "Enables DMA remapping isolation for stronger device boundary hardening";
    })

    (testLib.assertContains {
      id = "cpu-intel-005";
      name = "IOMMU strict mode enabled";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "iommu.strict=1";
      severity = "high";
      rationale = "Forces strict IOTLB invalidation for stronger DMA protection";
    })

    (testLib.assertContains {
      id = "cpu-intel-006";
      name = "TSX disabled";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "tsx=off";
      severity = "high";
      rationale = "Reduces CPU attack surface tied to TSX side-channel classes";
    })

    (testLib.assertContains {
      id = "cpu-intel-007";
      name = "Speculative Store Bypass mitigation forced on";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "spec_store_bypass_disable=on";
      severity = "high";
      rationale = "Forces mitigation path for Spectre-v4 style speculation leaks";
    })

    (testLib.assertEqual {
      id = "cpu-intel-008";
      name = "kernel pointers are restricted";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "kernel.kptr_restrict"
      ];
      expected = 2;
      severity = "high";
      rationale = "Prevents kernel pointer exposure to unprivileged userspace";
    })

    (testLib.assertEqual {
      id = "cpu-intel-009";
      name = "kernel dmesg is restricted";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "kernel.dmesg_restrict"
      ];
      expected = 1;
      severity = "high";
      rationale = "Blocks unprivileged read access to kernel logs";
    })

    (testLib.assertEqual {
      id = "cpu-intel-010";
      name = "unprivileged BPF is disabled";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "kernel.unprivileged_bpf_disabled"
      ];
      expected = 1;
      severity = "high";
      rationale = "Reduces kernel attack surface from unprivileged eBPF entry points";
    })

    (testLib.assertStringContains {
      id = "cpu-intel-011";
      name = "kvm_intel nested virtualization is explicitly enabled";
      inherit config;
      path = [
        "boot"
        "extraModprobeConfig"
      ];
      substring = "options kvm_intel nested=1";
      severity = "medium";
      rationale = "Makes Intel KVM nested behavior explicit and reproducible";
    })

    (testLib.assertStringContains {
      id = "cpu-intel-012";
      name = "kvm_intel EPT is explicitly enabled";
      inherit config;
      path = [
        "boot"
        "extraModprobeConfig"
      ];
      substring = "options kvm_intel ept=1";
      severity = "medium";
      rationale = "Pins Intel KVM memory translation path explicitly";
    })

    (testLib.assertStringContains {
      id = "cpu-intel-013";
      name = "kvm_intel APICv is explicitly enabled";
      inherit config;
      path = [
        "boot"
        "extraModprobeConfig"
      ];
      substring = "options kvm_intel enable_apicv=1";
      severity = "medium";
      rationale = "Pins Intel KVM interrupt virtualization behavior explicitly";
    })
  ];
in
  pkgs.runCommand "eval-hardware-cpu-intel" {} (
    testLib.mkCheckScript {
      name = "hardware/cpu-intel";
      assertionResults = assertions;
    }
  )
