# Eval tests for shared-modules/graphics/audio.nix
# Verifies minimal no-legacy PipeWire baseline.
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
      rationale = "PipeWire is the shared modern audio daemon baseline";
    })

    (testLib.assertEnabled {
      id = "audio-002";
      name = "Pipewire audio mode enabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "audio"
        "enable"
      ];
      severity = "critical";
      rationale = "Audio mode must be explicit for predictable module behavior";
    })

    (testLib.assertEnabled {
      id = "audio-003";
      name = "Pipewire socket activation enabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "socketActivation"
      ];
      severity = "high";
      rationale = "On-demand startup keeps baseline lean without idle daemon overhead";
    })

    (testLib.assertDisabled {
      id = "audio-004";
      name = "Pipewire system-wide mode disabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "systemWide"
      ];
      severity = "high";
      rationale = "Per-user isolation is preferred in shared baseline";
    })

    (testLib.assertEnabled {
      id = "audio-005";
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

    (testLib.assertDisabled {
      id = "audio-006";
      name = "32-bit ALSA support disabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "alsa"
        "support32Bit"
      ];
      severity = "high";
      rationale = "Shared baseline avoids optional 32-bit compatibility footprint";
    })

    (testLib.assertDisabled {
      id = "audio-007";
      name = "Pipewire PulseAudio emulation disabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "pulse"
        "enable"
      ];
      severity = "high";
      rationale = "No-legacy baseline should not expose PulseAudio compatibility layer";
    })

    (testLib.assertDisabled {
      id = "audio-008";
      name = "Pipewire JACK emulation disabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "jack"
        "enable"
      ];
      severity = "medium";
      rationale = "JACK stack stays out of shared baseline unless host explicitly needs it";
    })

    (testLib.assertDisabled {
      id = "audio-009";
      name = "RAOP firewall opening disabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "raopOpenFirewall"
      ];
      severity = "high";
      rationale = "Shared baseline must not open network audio ports";
    })

    (testLib.assertEnabled {
      id = "audio-010";
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
      id = "audio-011";
      name = "PulseAudio daemon disabled";
      inherit config;
      path = [
        "services"
        "pulseaudio"
        "enable"
      ];
      severity = "critical";
      rationale = "PulseAudio daemon must remain off in PipeWire-only baseline";
    })

    (testLib.assertEnabled {
      id = "audio-012";
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
