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
        rationale="Shared Intel baseline must request kvm-intel module load on boot.",
    )
    assert_command(
        "vm-cpu-intel-002",
        "kvm-intel module artifact exists for current kernel",
        "ls /run/current-system/kernel-modules/lib/modules/\"$(uname -r)\"/kernel/arch/x86/kvm/kvm-intel.ko* >/dev/null",
        severity="high",
        rationale="Kernel module payload for Intel virtualization must be present.",
    )
    assert_command(
        "vm-cpu-intel-003",
        "kvm_intel runtime state follows VMX capability",
        "sh -c 'if grep -qw vmx /proc/cpuinfo; then lsmod | grep -q \"^kvm_intel[[:space:]]\"; else ! lsmod | grep -q \"^kvm_intel[[:space:]]\"; fi'",
        severity="high",
        rationale="CI VMs may expose CPUs without VMX; module should load only when capability is present.",
    )
    assert_command(
        "vm-cpu-intel-004",
        "kvm_intel sysfs interface follows VMX capability",
        "sh -c 'if grep -qw vmx /proc/cpuinfo; then test -d /sys/module/kvm_intel/parameters; else test ! -d /sys/module/kvm_intel/parameters; fi'",
        severity="medium",
        rationale="kvm_intel sysfs interface exists only when module is loadable.",
    )
    assert_command(
        "vm-cpu-intel-005",
        "intel_iommu kernel parameter is active",
        "grep -Eq '(^| )intel_iommu=on( |$)' /proc/cmdline",
        severity="high",
        rationale="Intel IOMMU should be explicitly enabled for DMA isolation.",
    )
    assert_command(
        "vm-cpu-intel-006",
        "TSX-off kernel parameter is active",
        "grep -Eq '(^| )tsx=off( |$)' /proc/cmdline",
        severity="high",
        rationale="TSX should be disabled to reduce speculative execution attack surface.",
    )
    assert_command(
        "vm-cpu-intel-007",
        "kvm_intel nested virtualization option is materialized",
        "grep -R -E '^[[:space:]]*options[[:space:]]+kvm_intel[[:space:]]+.*nested=1' /etc/modprobe.d >/dev/null",
        severity="medium",
        rationale="Nested virtualization policy should be explicit in generated modprobe config.",
    )
    assert_command(
        "vm-cpu-intel-008",
        "kvm_intel EPT option is materialized",
        "grep -R -E '^[[:space:]]*options[[:space:]]+kvm_intel[[:space:]]+.*ept=1' /etc/modprobe.d >/dev/null",
        severity="medium",
        rationale="EPT policy should be explicit in generated modprobe config.",
    )
    assert_command(
        "vm-cpu-intel-009",
        "kvm_intel APICv option is materialized",
        "grep -R -E '^[[:space:]]*options[[:space:]]+kvm_intel[[:space:]]+.*enable_apicv=1' /etc/modprobe.d >/dev/null",
        severity="medium",
        rationale="APICv policy should be explicit in generated modprobe config.",
    )
    assert_command(
        "vm-cpu-intel-010",
        "no failed units after Intel CPU policy activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="CPU baseline policy must not introduce startup failures.",
    )
  '';
}
