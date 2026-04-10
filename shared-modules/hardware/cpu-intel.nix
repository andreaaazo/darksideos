# Shared Intel CPU baseline.
# ONLY contains what is universally true for any machine with an Intel CPU.
# Host-specific policy belongs in hosts/<hostname>/default.nix.
{lib, ...}: {
  hardware = {
    # Applies Intel microcode patches at boot to fix CPU bugs and security vulnerabilities (Spectre, Meltdown, Downfall, etc.).
    cpu.intel.updateMicrocode = true;
    # Installs proprietary firmware blobs for WiFi, Bluetooth, and other peripherals (mkDefault allows per-host override).
    enableRedistributableFirmware = lib.mkDefault true;
  };

  boot = {
    # Loads Intel VT-x virtualization kernel module (required for KVM/QEMU virtual machines and some container runtimes).
    kernelModules = ["kvm-intel"];

    # CPU hardening defaults: favor security/integrity over maximum raw throughput.
    kernelParams = [
      "intel_iommu=on"
      "iommu.strict=1"
      "tsx=off"
      "spec_store_bypass_disable=on"
    ];

    kernel.sysctl = {
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "kernel.unprivileged_bpf_disabled" = 1;
    };

    extraModprobeConfig = ''
      options kvm_intel nested=1
      options kvm_intel ept=1
      options kvm_intel enable_apicv=1
    '';
  };
}
