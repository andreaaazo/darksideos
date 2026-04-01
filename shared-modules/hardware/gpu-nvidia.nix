# Shared NVIDIA baseline.
# ONLY contains what is universally true for any machine with an NVIDIA GPU.
# Host-specific policy belongs in hosts/<hostname>/default.nix.
{ config, ... }:
{
  # Tells NixOS to use the proprietary NVIDIA driver instead of nouveau (required for CUDA, Wayland compositing, and full GPU performance).
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    # Enables NVIDIA Container Toolkit so Docker/Podman containers can access the GPU (required for containerized CUDA/ML workloads).
    nvidia-container-toolkit.enable = true;

    graphics = {
      # Enables the OpenGL/Vulkan graphics stack (required for any GPU-accelerated rendering).
      enable = true;
      # Installs 32-bit NVIDIA/Mesa libraries (required for Steam, Wine, and legacy 32-bit applications).
      enable32Bit = true;

    };

    nvidia = {
      # Pins the NVIDIA driver to the latest version matching the running kernel (ensures compatibility between kernel and driver).
      package = config.boot.kernelPackages.nvidiaPackages.latest;
      # Enables NVIDIA kernel modesetting (required for any Wayland compositor to function, harmless on X11).
      modesetting.enable = true;
      # Saves and restores GPU VRAM state on suspend/resume via systemd (prevents black screen or corruption after waking from sleep).
      powerManagement.enable = true;
      # Do not install the nvidia-settings GUI tool (no bloat).
      nvidiaSettings = false;
    };
  };

  boot.kernelParams = [
    "nvidia-drm.fbdev=1" # Registers an NVIDIA framebuffer device for clean TTY rendering and boot console at native resolution (default since driver 570+).
    "nvidia-drm.modeset=1" # Enables DRM kernel modesetting via kernel parameter (explicit match for modesetting.enable, required for Wayland).
  ];

}
