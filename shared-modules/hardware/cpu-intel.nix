# Shared Intel CPU baseline.
# ONLY contains what is universally true for any machine with an Intel CPU.
# Host-specific policy belongs in hosts/<hostname>/default.nix.
{lib, ...}: {
  # Import cross-vendor CPU hardening baseline.
  imports = [
    ./cpu-base.nix
  ];

  # Intel-specific hardware policy namespace.
  hardware = {
    # Applies Intel microcode patches at boot to fix CPU bugs and security vulnerabilities (Spectre, Meltdown, Downfall, etc.).
    cpu.intel.updateMicrocode = true;
    # Installs proprietary firmware blobs for WiFi, Bluetooth, and other peripherals (mkDefault allows per-host override).
    enableRedistributableFirmware = lib.mkDefault true;
  };

  # Intel-specific boot/runtime tuning namespace.
  boot = {
    # Loads Intel VT-x virtualization kernel module (required for KVM/QEMU virtual machines and some container runtimes).
    kernelModules = ["kvm-intel"];

    # CPU hardening defaults: favor security/integrity over maximum raw throughput.
    kernelParams = [
      # Enable Intel IOMMU for DMA remapping and device isolation.
      "intel_iommu=on"
      # Disable TSX to reduce exposure to TSX-related side-channel classes.
      "tsx=off"
    ];

    # KVM Intel module parameter overrides.
    extraModprobeConfig = ''
      # Allow nested virtualization for Intel guests.
      options kvm_intel nested=1
      # Keep Extended Page Tables enabled for virtualization performance.
      options kvm_intel ept=1
      # Keep APICv acceleration enabled when supported by hardware.
      options kvm_intel enable_apicv=1
    '';
  };
}
