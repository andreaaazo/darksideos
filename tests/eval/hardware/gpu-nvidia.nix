# Eval tests for shared-modules/hardware/gpu-nvidia.nix
# Verifies NVIDIA GPU baseline configuration.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../shared-modules/hardware/gpu-nvidia.nix
    ];
  };

  assertions = [
    (testLib.assertContains {
      id = "gpu-nvidia-001";
      name = "NVIDIA video driver selected";
      inherit config;
      path = [
        "services"
        "xserver"
        "videoDrivers"
      ];
      element = "nvidia";
      severity = "critical";
      rationale = "Proprietary driver required for CUDA, Wayland, full performance";
    })

    (testLib.assertEnabled {
      id = "gpu-nvidia-002";
      name = "NVIDIA container toolkit enabled";
      inherit config;
      path = [
        "hardware"
        "nvidia-container-toolkit"
        "enable"
      ];
      severity = "high";
      rationale = "Required for GPU access in Docker/Podman containers";
    })

    (testLib.assertEnabled {
      id = "gpu-nvidia-003";
      name = "Graphics stack enabled";
      inherit config;
      path = [
        "hardware"
        "graphics"
        "enable"
      ];
      severity = "critical";
      rationale = "OpenGL/Vulkan required for GPU-accelerated rendering";
    })

    (testLib.assertEnabled {
      id = "gpu-nvidia-004";
      name = "32-bit graphics libraries enabled";
      inherit config;
      path = [
        "hardware"
        "graphics"
        "enable32Bit"
      ];
      severity = "high";
      rationale = "Required for Steam, Wine, and 32-bit applications";
    })

    (testLib.assertEnabled {
      id = "gpu-nvidia-005";
      name = "NVIDIA modesetting enabled";
      inherit config;
      path = [
        "hardware"
        "nvidia"
        "modesetting"
        "enable"
      ];
      severity = "critical";
      rationale = "Required for Wayland compositors to function";
    })

    (testLib.assertEnabled {
      id = "gpu-nvidia-006";
      name = "NVIDIA power management enabled";
      inherit config;
      path = [
        "hardware"
        "nvidia"
        "powerManagement"
        "enable"
      ];
      severity = "high";
      rationale = "Prevents black screen after suspend/resume";
    })

    (testLib.assertDisabled {
      id = "gpu-nvidia-007";
      name = "nvidia-settings GUI disabled";
      inherit config;
      path = [
        "hardware"
        "nvidia"
        "nvidiaSettings"
      ];
      severity = "medium";
      rationale = "No bloat - settings managed via NixOS config";
    })

    (testLib.assertContains {
      id = "gpu-nvidia-008";
      name = "NVIDIA framebuffer kernel param set";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "nvidia-drm.fbdev=1";
      severity = "high";
      rationale = "Clean TTY rendering at native resolution";
    })

    (testLib.assertContains {
      id = "gpu-nvidia-009";
      name = "NVIDIA modesetting kernel param set";
      inherit config;
      path = [
        "boot"
        "kernelParams"
      ];
      element = "nvidia-drm.modeset=1";
      severity = "critical";
      rationale = "DRM modesetting required for Wayland";
    })
  ];
in
  pkgs.runCommand "eval-hardware-gpu-nvidia" {} (
    testLib.mkCheckScript {
      name = "hardware/gpu-nvidia";
      assertionResults = assertions;
    }
  )
