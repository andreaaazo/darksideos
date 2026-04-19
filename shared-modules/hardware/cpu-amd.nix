# Shared AMD CPU baseline.
# ONLY contains what is universally true for any machine with an AMD CPU.
# Host-specific policy belongs in hosts/<hostname>/default.nix.
{lib, ...}: {
  # Import cross-vendor CPU hardening baseline.
  imports = [
    ./cpu-base.nix
  ];

  # AMD-specific hardware policy namespace.
  hardware = {
    # Applies AMD microcode patches at boot to fix CPU bugs and security vulnerabilities.
    cpu.amd.updateMicrocode = true;
    # Installs proprietary firmware blobs for WiFi, Bluetooth, and other peripherals (mkDefault allows per-host override).
    enableRedistributableFirmware = lib.mkDefault true;
  };

  # AMD-specific boot/runtime tuning namespace.
  boot = {
    # Loads AMD-V virtualization kernel module (required for KVM/QEMU virtual machines and some container runtimes).
    kernelModules = ["kvm-amd"];

    # CPU hardening defaults: favor security/integrity over maximum raw throughput.
    kernelParams = [
      # Enable AMD IOMMU for DMA remapping and device isolation.
      "amd_iommu=on"
    ];

    # KVM AMD module parameter overrides.
    extraModprobeConfig = ''
      # Allow nested virtualization for AMD guests.
      options kvm_amd nested=1
      # Keep Nested Page Tables enabled for virtualization performance.
      options kvm_amd npt=1
      # Keep AVIC enabled for lower interrupt virtualization overhead.
      options kvm_amd avic=1
    '';
  };
}
