# Eval integration test for composed shared hardware baseline.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../shared-modules/hardware/audio.nix
      ../../../shared-modules/hardware/bluetooth.nix
      ../../../shared-modules/hardware/cpu-intel.nix
      ../../../shared-modules/hardware/gpu-nvidia.nix
    ];
  };
  assertions = [
    (testLib.assertEnabled {
      id = "module-hardware-001";
      name = "pipewire enabled";
      inherit config;
      path = ["services" "pipewire" "enable"];
      severity = "high";
      rationale = "Hardware integration must keep PipeWire audio stack enabled.";
    })
    (testLib.assertDisabled {
      id = "module-hardware-002";
      name = "pulseaudio disabled";
      inherit config;
      path = ["services" "pulseaudio" "enable"];
      severity = "high";
      rationale = "Hardware integration must avoid mixed PulseAudio daemon stack.";
    })
    (testLib.assertEnabled {
      id = "module-hardware-003";
      name = "bluetooth enabled";
      inherit config;
      path = ["hardware" "bluetooth" "enable"];
      severity = "medium";
      rationale = "Hardware integration must preserve shared Bluetooth baseline.";
    })
    (testLib.assertContains {
      id = "module-hardware-004";
      name = "nvidia drm modeset kernel param present";
      inherit config;
      path = ["boot" "kernelParams"];
      element = "nvidia-drm.modeset=1";
      severity = "high";
      rationale = "Hardware integration must preserve NVIDIA modesetting policy.";
    })
  ];
in
  pkgs.runCommand "eval-module-hardware" {} (
    testLib.mkCheckScript {
      name = "module/hardware";
      assertionResults = assertions;
    }
  )
