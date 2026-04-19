# VM test for shared-modules/hardware/cpu-amd.nix
{vmLib}:
vmLib.mkVmTest {
  name = "hardware-cpu-amd";
  nodeModules = [
    ({lib, ...}: {
      # VM fixture: skip huge firmware closure download.
      # Firmware policy itself is covered in eval tests.
      hardware.enableRedistributableFirmware = lib.mkForce false;
    })
    ../../../../shared-modules/hardware/cpu-amd.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-cpu-amd-001",
        "kvm-amd is listed in modules-load config",
        "test -f /etc/modules-load.d/nixos.conf && grep -x 'kvm-amd' /etc/modules-load.d/nixos.conf >/dev/null",
        severity="high",
        rationale="Shared AMD baseline must request kvm-amd module load on boot.",
    )
    assert_command(
        "vm-cpu-amd-002",
        "kvm-amd module artifact exists for current kernel",
        "ls /run/current-system/kernel-modules/lib/modules/\"$(uname -r)\"/kernel/arch/x86/kvm/kvm-amd.ko* >/dev/null",
        severity="high",
        rationale="Kernel module payload for AMD virtualization must be present.",
    )
    assert_command(
        "vm-cpu-amd-003",
        "kvm_amd runtime state follows SVM capability",
        "sh -c 'if grep -qw svm /proc/cpuinfo; then lsmod | grep -q \"^kvm_amd[[:space:]]\"; else ! lsmod | grep -q \"^kvm_amd[[:space:]]\"; fi'",
        severity="high",
        rationale="CI VMs may expose CPUs without SVM; module should load only when capability is present.",
    )
    assert_command(
        "vm-cpu-amd-004",
        "kvm_amd sysfs interface follows SVM capability",
        "sh -c 'if grep -qw svm /proc/cpuinfo; then test -d /sys/module/kvm_amd/parameters; else test ! -d /sys/module/kvm_amd/parameters; fi'",
        severity="medium",
        rationale="kvm_amd sysfs interface exists only when module is loadable.",
    )
    assert_command(
        "vm-cpu-amd-005",
        "amd_iommu kernel parameter is active",
        "grep -Eq '(^| )amd_iommu=on( |$)' /proc/cmdline",
        severity="high",
        rationale="AMD IOMMU should be explicitly enabled for DMA isolation.",
    )
    assert_command(
        "vm-cpu-amd-006",
        "kvm_amd nested virtualization option is materialized",
        "grep -R -E '^[[:space:]]*options[[:space:]]+kvm_amd[[:space:]]+.*nested=1' /etc/modprobe.d >/dev/null",
        severity="medium",
        rationale="Nested virtualization policy should be explicit in generated modprobe config.",
    )
    assert_command(
        "vm-cpu-amd-007",
        "kvm_amd NPT option is materialized",
        "grep -R -E '^[[:space:]]*options[[:space:]]+kvm_amd[[:space:]]+.*npt=1' /etc/modprobe.d >/dev/null",
        severity="medium",
        rationale="NPT policy should be explicit in generated modprobe config.",
    )
    assert_command(
        "vm-cpu-amd-008",
        "kvm_amd AVIC option is materialized",
        "grep -R -E '^[[:space:]]*options[[:space:]]+kvm_amd[[:space:]]+.*avic=1' /etc/modprobe.d >/dev/null",
        severity="medium",
        rationale="AVIC policy should be explicit in generated modprobe config.",
    )
    assert_command(
        "vm-cpu-amd-009",
        "no failed units after AMD CPU policy activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="CPU baseline policy must not introduce startup failures.",
    )
  '';
}
