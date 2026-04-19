# VM test for shared-modules/hardware/cpu-base.nix
{vmLib}:
vmLib.mkVmTest {
  name = "hardware-cpu-base";
  nodeModules = [
    ../../../../shared-modules/hardware/cpu-base.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-cpu-base-001",
        "iommu strict mode kernel parameter is active",
        "grep -Eq '(^| )iommu\\.strict=1( |$)' /proc/cmdline",
        severity="high",
        rationale="Strict IOMMU mode should be enforced at runtime.",
    )
    assert_command(
        "vm-cpu-base-002",
        "SSB mitigation kernel parameter is active",
        "grep -Eq '(^| )spec_store_bypass_disable=on( |$)' /proc/cmdline",
        severity="high",
        rationale="Speculative Store Bypass mitigation must stay forced on.",
    )
    assert_command(
        "vm-cpu-base-003",
        "SLAB merging is disabled via kernel parameter",
        "grep -Eq '(^| )slab_nomerge( |$)' /proc/cmdline",
        severity="high",
        rationale="Disables slab object merging to reduce heap exploitation primitives.",
    )
    assert_command(
        "vm-cpu-base-004",
        "page allocator free-list shuffling is enabled",
        "grep -Eq '(^| )page_alloc\\.shuffle=1( |$)' /proc/cmdline",
        severity="high",
        rationale="Adds entropy to physical page allocation behavior.",
    )
    assert_command(
        "vm-cpu-base-005",
        "kernel stack offset randomization is enabled",
        "grep -Eq '(^| )randomize_kstack_offset=on( |$)' /proc/cmdline",
        severity="high",
        rationale="Adds syscall-time stack offset randomization against stack-based attacks.",
    )
    assert_command(
        "vm-cpu-base-006",
        "kernel pointer exposure is restricted",
        "sysctl -n kernel.kptr_restrict | grep -x '2'",
        severity="high",
        rationale="Kernel pointer visibility should be maximally restricted.",
    )
    assert_command(
        "vm-cpu-base-007",
        "kernel dmesg access is restricted",
        "sysctl -n kernel.dmesg_restrict | grep -x '1'",
        severity="high",
        rationale="Unprivileged users should not read kernel logs.",
    )
    assert_command(
        "vm-cpu-base-008",
        "unprivileged BPF is disabled at runtime",
        "test \"$(sysctl -n kernel.unprivileged_bpf_disabled)\" -ge 1",
        severity="high",
        rationale="Runtime must block unprivileged eBPF or stronger.",
    )
    assert_command(
        "vm-cpu-base-009",
        "ASLR is fully enabled",
        "sysctl -n kernel.randomize_va_space | grep -x '2'",
        severity="high",
        rationale="Full virtual address randomization improves exploit resistance.",
    )
    assert_command(
        "vm-cpu-base-010",
        "ptrace scope is restricted",
        "sysctl -n kernel.yama.ptrace_scope | grep -x '2'",
        severity="high",
        rationale="Restricts cross-process introspection to tighter trust boundaries.",
    )
    assert_command(
        "vm-cpu-base-011",
        "perf events are restricted to privileged users",
        "sysctl -n kernel.perf_event_paranoid | grep -x '3'",
        severity="high",
        rationale="Reduces side-channel and introspection exposure from perf interfaces.",
    )
    assert_command(
        "vm-cpu-base-012",
        "kexec loading is disabled",
        "sysctl -n kernel.kexec_load_disabled | grep -x '1'",
        severity="high",
        rationale="Prevents runtime kernel replacement from userspace.",
    )
    assert_command(
        "vm-cpu-base-013",
        "unprivileged userfaultfd is disabled",
        "sysctl -n vm.unprivileged_userfaultfd | grep -x '0'",
        severity="high",
        rationale="Removes a common exploitation primitive from unprivileged contexts.",
    )
    assert_command(
        "vm-cpu-base-014",
        "protected symlinks are enabled",
        "sysctl -n fs.protected_symlinks | grep -x '1'",
        severity="high",
        rationale="Mitigates symlink race attacks in sticky world-writable directories.",
    )
    assert_command(
        "vm-cpu-base-015",
        "protected hardlinks are enabled",
        "sysctl -n fs.protected_hardlinks | grep -x '1'",
        severity="high",
        rationale="Mitigates hardlink-based privilege escalation patterns.",
    )
    assert_command(
        "vm-cpu-base-016",
        "protected FIFOs policy is strict",
        "sysctl -n fs.protected_fifos | grep -x '2'",
        severity="high",
        rationale="Blocks unsafe FIFO usage in sticky world-writable directories.",
    )
    assert_command(
        "vm-cpu-base-017",
        "protected regular files policy is strict",
        "sysctl -n fs.protected_regular | grep -x '2'",
        severity="high",
        rationale="Blocks unsafe regular-file usage in sticky world-writable directories.",
    )
    assert_command(
        "vm-cpu-base-018",
        "no failed units after CPU base policy activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="CPU hardening baseline must not introduce startup failures.",
    )
  '';
}
