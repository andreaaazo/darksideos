# Shared NVIDIA baseline.
# ONLY contains what is universally true for any machine with an NVIDIA GPU.
# Host-specific policy belongs in hosts/<hostname>/default.nix.
{config, ...}: {
  # Tells NixOS to use the proprietary NVIDIA driver instead of nouveau (required for CUDA, Wayland compositing, and full GPU performance).
  services.xserver.videoDrivers = ["nvidia"];

  # NVIDIA hardware namespace (driver, graphics stack, and power behavior).
  hardware = {
    # Keep shared baseline lean: no container GPU runtime unless explicitly needed by host.
    nvidia-container-toolkit.enable = false;

    # Core graphics stack toggles used by OpenGL/Vulkan clients.
    graphics = {
      # Enables the OpenGL/Vulkan graphics stack (required for any GPU-accelerated rendering).
      enable = true;
      # Minimal baseline: keep 32-bit compatibility disabled unless a host explicitly needs it.
      enable32Bit = false;
    };

    # NVIDIA driver policy and runtime behavior.
    nvidia = {
      # Pins the NVIDIA driver to the latest version matching the running kernel (ensures compatibility between kernel and driver).
      package = config.boot.kernelPackages.nvidiaPackages.latest;
      # Prefer modern open NVIDIA kernel modules on supported hardware.
      open = true;
      # Enables NVIDIA kernel modesetting (required for any Wayland compositor to function, harmless on X11).
      modesetting.enable = true;
      # Saves and restores GPU VRAM state on suspend/resume via systemd (prevents black screen or corruption after waking from sleep).
      powerManagement.enable = true;
      # Keep battery-oriented tuning disabled in shared profile.
      powerManagement.finegrained = false;
      # Disable NVIDIA Dynamic Boost policy in shared baseline.
      dynamicBoost.enable = false;
      # Do not install the nvidia-settings GUI tool (no bloat).
      nvidiaSettings = false;
    };
  };

  # Boot-time NVIDIA kernel parameter and module policy.
  boot = {
    # NVIDIA DRM kernel command-line parameters.
    kernelParams = [
      # Enable fbdev emulation for clean virtual console rendering on NVIDIA DRM.
      "nvidia-drm.fbdev=1" # Registers an NVIDIA framebuffer device for clean TTY rendering and boot console at native resolution (default since driver 570+).
      # Enable DRM modeset path required by Wayland compositors.
      "nvidia-drm.modeset=1" # Enables DRM kernel modesetting via kernel parameter (explicit match for modesetting.enable, required for Wayland).
    ];

    # Restrict GPU profiling interfaces to privileged users.
    extraModprobeConfig = ''
      options nvidia NVreg_RestrictProfilingToAdminUsers=1
    '';
  };
}
