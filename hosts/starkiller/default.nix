# Compositor for starkiller.
# This file imports modules and declares host-specific overrides.
{pkgs, ...}: {
  imports = [
    # Disk layout
    ./disk.nix

    # Hardware
    ./hardware-configuration.nix

    # Shared modules
    ../../shared-modules/core
    ../../shared-modules/graphics
    ../../shared-modules/hardware/gpu-nvidia.nix
    ../../shared-modules/hardware/cpu-intel.nix
    ../../shared-modules/hardware/bluetooth.nix
    ../../shared-modules/hardware/audio.nix
    ../../shared-modules/impermanence

    # User environment
    ../../shared-modules/home

    # Monitors
    ./monitors.nix
  ];

  hardware = {
    nvidia = {
      # Use NVIDIA's open-source kernel module instead of the closed-source blob (required for Ada Lovelace+, better Wayland/suspend support).
      open = true;
      # Disable D3/RTD3 dynamic GPU power-off.
      powerManagement.finegrained = false;
    };
    graphics = {
      extraPackages = with pkgs; [
        # Bridges VA-API video decode calls to NVIDIA's NVDEC hardware decoder (required for hardware-accelerated video playback in browsers/players).
        nvidia-vaapi-driver
      ];
    };
  };

  environment.sessionVariables = {
    # Tells VA-API clients to use the NVIDIA backend instead of the default (required for nvidia-vaapi-driver to be selected).
    LIBVA_DRIVER_NAME = "nvidia";
    # Forces X11/GLX applications to load NVIDIA's OpenGL library instead of Mesa (required when NVIDIA is the only/primary GPU).
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # Tells nvidia-vaapi-driver to use direct rendering instead of going through GBM (better performance, fewer copies).
    NVD_BACKEND = "direct";
  };
}
