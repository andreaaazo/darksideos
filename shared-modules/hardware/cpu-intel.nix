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

  # Loads Intel VT-x virtualization kernel module (required for KVM/QEMU virtual machines and some container runtimes).
  boot.kernelModules = ["kvm-intel"];
}
