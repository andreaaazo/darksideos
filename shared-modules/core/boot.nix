# Boot configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{ pkgs, ... }:
{
  boot = {
    loader = {
      systemd-boot = {
        # Use systemd-boot as UEFI bootloader (lightweight, no GRUB overhead).
        enable = true;
        # Keep only the last 4 NixOS generations in the boot menu (prevents /boot from filling up).
        configurationLimit = 4;
        # Disables kernel command-line editing at boot (prevents anyone from getting a root shell by appending init=/bin/sh)
        editor = false;
      };
      # Allows the bootloader to write EFI NVRAM entries (required for systemd-boot to register itself).
      efi.canTouchEfiVariables = true;
      # Wait 3 seconds at boot menu before auto-selecting the default entry.
      timeout = 3;
    };
    # Use the latest stable kernel
    kernelPackages = pkgs.linuxPackages_latest;
  };
}
