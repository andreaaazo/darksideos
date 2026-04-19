# Boot configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{
  lib,
  pkgs,
  ...
}: {
  # Boot-level configuration namespace for kernel, initrd, and bootloader behavior.
  boot = {
    # Keep initrd logs quiet to reduce boot noise and avoid unnecessary console churn.
    initrd.verbose = false;
    # Limit kernel console verbosity (errors/warnings only).
    # Use mkDefault to stay compatible with NixOS test instrumentation overrides.
    consoleLogLevel = lib.mkDefault 3;

    # Bootloader configuration namespace.
    loader = {
      # systemd-boot-specific options.
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
    # Use the latest stable kernel
    kernelPackages = pkgs.linuxPackages_latest;
    # Minimize boot-time log noise while keeping diagnostics available when needed.
    kernelParams = [
      # Reduces boot-time console noise for a clean startup.
      "quiet"
      # Keeps kernel console output at warning-and-above severity.
      "loglevel=3"
      # Reduces udev daemon verbosity during early userspace startup.
      "udev.log_level=3"
    ];
  };
}
