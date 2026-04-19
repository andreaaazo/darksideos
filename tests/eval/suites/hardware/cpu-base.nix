# Eval tests for shared-modules/hardware/cpu-base.nix
# Verifies cross-vendor CPU hardening baseline.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../../shared-modules/hardware/cpu-base.nix
    ];
  };

  assertions = [
    (testLib.assertContains {
      id = "cpu-base-001";
      name = "IOMMU strict mode enabled";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "iommu.strict=1";
      severity = "high";
      rationale = "Forces strict IOTLB invalidation for stronger DMA protection.";
    })

    (testLib.assertContains {
      id = "cpu-base-002";
      name = "Speculative Store Bypass mitigation forced on";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "spec_store_bypass_disable=on";
      severity = "high";
      rationale = "Forces mitigation path for Spectre-v4 style speculation leaks.";
    })

    (testLib.assertContains {
      id = "cpu-base-003";
      name = "SLAB merging disabled";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "slab_nomerge";
      severity = "high";
      rationale = "Reduces slab heap exploitation primitives.";
    })

    (testLib.assertContains {
      id = "cpu-base-004";
      name = "Page allocator free-list shuffle enabled";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "page_alloc.shuffle=1";
      severity = "high";
      rationale = "Improves allocator entropy against deterministic memory abuse.";
    })

    (testLib.assertContains {
      id = "cpu-base-005";
      name = "Kernel stack offset randomization enabled";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "randomize_kstack_offset=on";
      severity = "high";
      rationale = "Adds per-syscall stack offset jitter against stack attacks.";
    })

    (testLib.assertEqual {
      id = "cpu-base-006";
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
      rationale = "Prevents kernel pointer exposure to unprivileged userspace.";
    })

    (testLib.assertEqual {
      id = "cpu-base-007";
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
      rationale = "Blocks unprivileged read access to kernel logs.";
    })

    (testLib.assertEqual {
      id = "cpu-base-008";
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
      rationale = "Reduces kernel attack surface from unprivileged eBPF entry points.";
    })

    (testLib.assertEqual {
      id = "cpu-base-009";
      name = "ASLR is fully enabled";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "kernel.randomize_va_space"
      ];
      expected = 2;
      severity = "high";
      rationale = "Full virtual address randomization improves exploit resistance.";
    })

    (testLib.assertEqual {
      id = "cpu-base-010";
      name = "ptrace scope is restricted";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "kernel.yama.ptrace_scope"
      ];
      expected = 2;
      severity = "high";
      rationale = "Restricts process introspection to tighter trust boundaries.";
    })

    (testLib.assertEqual {
      id = "cpu-base-011";
      name = "perf events are restricted";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "kernel.perf_event_paranoid"
      ];
      expected = 3;
      severity = "high";
      rationale = "Reduces side-channel and introspection exposure from perf interfaces.";
    })

    (testLib.assertEqual {
      id = "cpu-base-012";
      name = "kexec loading is disabled";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "kernel.kexec_load_disabled"
      ];
      expected = 1;
      severity = "high";
      rationale = "Prevents runtime kernel replacement from userspace.";
    })

    (testLib.assertEqual {
      id = "cpu-base-013";
      name = "unprivileged userfaultfd is disabled";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "vm.unprivileged_userfaultfd"
      ];
      expected = 0;
      severity = "high";
      rationale = "Removes a common exploitation primitive from unprivileged contexts.";
    })

    (testLib.assertEqual {
      id = "cpu-base-014";
      name = "protected symlinks are enabled";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "fs.protected_symlinks"
      ];
      expected = 1;
      severity = "high";
      rationale = "Mitigates symlink race attacks in sticky world-writable directories.";
    })

    (testLib.assertEqual {
      id = "cpu-base-015";
      name = "protected hardlinks are enabled";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "fs.protected_hardlinks"
      ];
      expected = 1;
      severity = "high";
      rationale = "Mitigates hardlink-based privilege escalation patterns.";
    })

    (testLib.assertEqual {
      id = "cpu-base-016";
      name = "protected FIFOs policy is strict";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "fs.protected_fifos"
      ];
      expected = 2;
      severity = "high";
      rationale = "Blocks unsafe FIFO handling in sticky world-writable directories.";
    })

    (testLib.assertEqual {
      id = "cpu-base-017";
      name = "protected regular files policy is strict";
      inherit config;
      path = [
        "boot"
        "kernel"
        "sysctl"
        "fs.protected_regular"
      ];
      expected = 2;
      severity = "high";
      rationale = "Blocks unsafe regular-file handling in sticky world-writable directories.";
    })
  ];
in
  pkgs.runCommand "eval-hardware-cpu-base" {} (
    testLib.mkCheckScript {
      name = "hardware/cpu-base";
      assertionResults = assertions;
    }
  )
