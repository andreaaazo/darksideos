# Eval tests for shared-modules/hardware/audio.nix
# Verifies minimal no-legacy PipeWire baseline.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../../shared-modules/hardware/audio.nix
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

    (testLib.assertEnabled {
      id = "audio-011";
      name = "WirePlumber ALSA ACP policy enabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "wireplumber"
        "extraConfig"
        "95-high-quality-audio"
        "monitor.alsa.properties"
        "alsa.use-acp"
      ];
      severity = "high";
      rationale = "Shared baseline should enforce deterministic ALSA card/profile handling";
    })

    (testLib.assertDisabled {
      id = "audio-012";
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
      id = "audio-013";
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

    (testLib.assertEqual {
      id = "audio-014";
      name = "Pipewire fallback clock rate is 48 kHz";
      inherit config;
      path = [
        "services"
        "pipewire"
        "extraConfig"
        "pipewire"
        "95-high-quality-audio"
        "context.properties"
        "default.clock.rate"
      ];
      expected = 48000;
      severity = "high";
      rationale = "Predictable fallback rate keeps baseline tuned for modern DAC chains";
    })

    (testLib.assertEqual {
      id = "audio-015";
      name = "Pipewire allowed rates cover hi-fi and studio set";
      inherit config;
      path = [
        "services"
        "pipewire"
        "extraConfig"
        "pipewire"
        "95-high-quality-audio"
        "context.properties"
        "default.clock.allowed-rates"
      ];
      expected = [
        44100
        48000
        88200
        96000
        176400
        192000
        352800
        384000
      ];
      severity = "high";
      rationale = "Source-matched rates reduce avoidable resampling drift on hi-res content";
    })

    (testLib.assertEqual {
      id = "audio-016";
      name = "Pipewire default quantum is set for stable playback";
      inherit config;
      path = [
        "services"
        "pipewire"
        "extraConfig"
        "pipewire"
        "95-high-quality-audio"
        "context.properties"
        "default.clock.quantum"
      ];
      expected = 2048;
      severity = "high";
      rationale = "Playback-optimized quantum reduces pops and glitches at high sample rates";
    })

    (testLib.assertEqual {
      id = "audio-017";
      name = "Pipewire minimum quantum is constrained";
      inherit config;
      path = [
        "services"
        "pipewire"
        "extraConfig"
        "pipewire"
        "95-high-quality-audio"
        "context.properties"
        "default.clock.min-quantum"
      ];
      expected = 1024;
      severity = "high";
      rationale = "Minimum quantum guardrail avoids unstable tiny buffers";
    })

    (testLib.assertEqual {
      id = "audio-018";
      name = "Pipewire maximum quantum is constrained";
      inherit config;
      path = [
        "services"
        "pipewire"
        "extraConfig"
        "pipewire"
        "95-high-quality-audio"
        "context.properties"
        "default.clock.max-quantum"
      ];
      expected = 8192;
      severity = "high";
      rationale = "Upper bound prevents runaway latency while preserving high-rate stability";
    })

    (testLib.assertEqual {
      id = "audio-019";
      name = "Pipewire resampler quality set to max precision";
      inherit config;
      path = [
        "services"
        "pipewire"
        "extraConfig"
        "pipewire"
        "95-high-quality-audio"
        "stream.properties"
        "resample.quality"
      ];
      expected = 14;
      severity = "high";
      rationale = "Highest resampler quality improves mathematical precision for conversion paths";
    })

    (testLib.assertEnabled {
      id = "audio-020";
      name = "Pipewire stream channel normalization enabled";
      inherit config;
      path = [
        "services"
        "pipewire"
        "extraConfig"
        "pipewire"
        "95-high-quality-audio"
        "stream.properties"
        "channelmix.normalize"
      ];
      severity = "medium";
      rationale = "Shared baseline should normalize channel mix to reduce clipping risk";
    })
  ];
in
  pkgs.runCommand "eval-hardware-audio" {} (
    testLib.mkCheckScript {
      name = "hardware/audio";
      assertionResults = assertions;
    }
  )
