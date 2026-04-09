# Eval tests for shared-modules/graphics/audio.nix
# Verifies Pipewire audio stack with ALSA/PulseAudio compatibility.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../shared-modules/graphics/audio.nix
    ];
  };

  assertions = [
    (testLib.assertEnabled {
      id = "audio-001";
      name = "Pipewire enabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "enable"
      ];
      severity = "critical";
      rationale = "Pipewire is the modern audio/video daemon replacing PulseAudio";
    })

    (testLib.assertEnabled {
      id = "audio-002";
      name = "ALSA compatibility enabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "alsa"
        "enable"
      ];
      severity = "high";
      rationale = "ALSA layer needed for games and low-level audio tools";
    })

    (testLib.assertEnabled {
      id = "audio-003";
      name = "32-bit ALSA support enabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "alsa"
        "support32Bit"
      ];
      severity = "high";
      rationale = "Required for Steam and Wine 32-bit games";
    })

    (testLib.assertEnabled {
      id = "audio-004";
      name = "PulseAudio compatibility enabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "pulse"
        "enable"
      ];
      severity = "high";
      rationale = "PulseAudio API compatibility for Firefox, Discord, desktop apps";
    })

    (testLib.assertEnabled {
      id = "audio-005";
      name = "WirePlumber session manager enabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "wireplumber"
        "enable"
      ];
      severity = "high";
      rationale = "Session manager handles device routing and hotplug";
    })

    (testLib.assertDisabled {
      id = "audio-006";
      name = "PulseAudio daemon disabled";
      inherit config;
      path = [
        "services"
        "pulseaudio"
        "enable"
      ];
      severity = "critical";
      rationale = "PulseAudio conflicts with Pipewire's compatibility layer";
    })

    (testLib.assertEnabled {
      id = "audio-007";
      name = "RealtimeKit enabled";
      inherit config;
      path = [
        "security"
        "rtkit"
        "enable"
      ];
      severity = "high";
      rationale = "Grants real-time priority to prevent audio crackling";
    })
  ];
in
  pkgs.runCommand "eval-graphics-audio" {} (
    testLib.mkCheckScript {
      name = "graphics/audio";
      assertionResults = assertions;
    }
  )
