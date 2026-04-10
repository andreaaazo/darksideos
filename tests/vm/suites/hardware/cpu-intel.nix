# VM test for shared-modules/hardware/cpu-intel.nix
{vmLib}:
vmLib.mkVmTest {
  name = "hardware-cpu-intel";
  nodeModules = [
    ({lib, ...}: {
      # VM fixture: skip huge firmware closure download.
      # Firmware policy itself is covered in eval tests.
      hardware.enableRedistributableFirmware = lib.mkForce false;
    })
    ../../../../shared-modules/hardware/cpu-intel.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-cpu-intel-001",
        "kvm-intel is listed in modules-load config",
        "test -f /etc/modules-load.d/nixos.conf && grep -x 'kvm-intel' /etc/modules-load.d/nixos.conf >/dev/null",
        severity="high",
        rationale="Shared Intel baseline must request kvm-intel module load on boot",
    )
    assert_command(
        "vm-cpu-intel-002",
        "kvm-intel module artifact exists for current kernel",
        "ls /run/current-system/kernel-modules/lib/modules/\"$(uname -r)\"/kernel/arch/x86/kvm/kvm-intel.ko* >/dev/null",
        severity="high",
        rationale="Kernel module payload for Intel virtualization must be present",
    )
    assert_command(
        "vm-cpu-intel-003",
        "kvm_intel module is loaded in running kernel",
        "lsmod | awk '{print $1}' | grep -x 'kvm_intel' >/dev/null",
        severity="high",
        rationale="Intel virtualization module should be active, not only present on disk",
    )
    assert_command(
        "vm-cpu-intel-004",
        "kvm_intel sysfs parameter interface exists",
        "test -d /sys/module/kvm_intel/parameters",
        severity="medium",
        rationale="Loaded Intel virtualization module should expose runtime tuning interface",
    )
    assert_command(
        "vm-cpu-intel-005",
        "intel_iommu kernel parameter is active",
        "grep -Eq '(^| )intel_iommu=on( |$)' /proc/cmdline",
        severity="high",
        rationale="IOMMU should be explicitly enabled for stronger DMA isolation",
    )
    assert_command(
        "vm-cpu-intel-006",
        "iommu strict mode kernel parameter is active",
        "grep -Eq '(^| )iommu\\.strict=1( |$)' /proc/cmdline",
        severity="high",
        rationale="Strict IOMMU mode should be enforced at runtime",
    )
    assert_command(
        "vm-cpu-intel-007",
        "TSX-off kernel parameter is active",
        "grep -Eq '(^| )tsx=off( |$)' /proc/cmdline",
        severity="high",
        rationale="TSX should be disabled to reduce speculative execution attack surface",
    )
    assert_command(
        "vm-cpu-intel-008",
        "SSB mitigation kernel parameter is active",
        "grep -Eq '(^| )spec_store_bypass_disable=on( |$)' /proc/cmdline",
        severity="high",
        rationale="Speculative Store Bypass mitigation must stay forced on",
    )
    assert_command(
        "vm-cpu-intel-009",
        "kernel pointer exposure is restricted",
        "sysctl -n kernel.kptr_restrict | grep -x '2'",
        severity="high",
        rationale="Kernel pointer visibility should be maximally restricted",
    )
    assert_command(
        "vm-cpu-intel-010",
        "kernel dmesg access is restricted",
        "sysctl -n kernel.dmesg_restrict | grep -x '1'",
        severity="high",
        rationale="Unprivileged users should not read kernel logs",
    )
    assert_command(
        "vm-cpu-intel-011",
        "unprivileged BPF is disabled at runtime",
        "test \"$(sysctl -n kernel.unprivileged_bpf_disabled)\" -ge 1",
        severity="high",
        rationale="Runtime must block unprivileged eBPF or stronger",
    )
    assert_command(
        "vm-cpu-intel-012",
        "kvm_intel nested virtualization option is materialized",
        "grep -R -E '^[[:space:]]*options[[:space:]]+kvm_intel[[:space:]]+.*nested=1' /etc/modprobe.d >/dev/null",
        severity="medium",
        rationale="Nested virtualization policy should be explicit in generated modprobe config",
    )
    assert_command(
        "vm-cpu-intel-013",
        "kvm_intel EPT option is materialized",
        "grep -R -E '^[[:space:]]*options[[:space:]]+kvm_intel[[:space:]]+.*ept=1' /etc/modprobe.d >/dev/null",
        severity="medium",
        rationale="EPT policy should be explicit in generated modprobe config",
    )
    assert_command(
        "vm-cpu-intel-014",
        "kvm_intel APICv option is materialized",
        "grep -R -E '^[[:space:]]*options[[:space:]]+kvm_intel[[:space:]]+.*enable_apicv=1' /etc/modprobe.d >/dev/null",
        severity="medium",
        rationale="APICv policy should be explicit in generated modprobe config",
    )
    assert_command(
        "vm-cpu-intel-015",
        "no failed units after Intel CPU policy activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="CPU baseline policy must not introduce startup failures",
    )
  '';
}
