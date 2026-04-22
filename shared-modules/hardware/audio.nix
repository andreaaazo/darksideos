# Minimal PipeWire audio stack.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{
  # PipeWire service namespace (audio server and compatibility layers).
  services.pipewire = {
    # Enables PipeWire as primary modern audio stack.
    enable = true;
    # Explicitly set audio mode instead of relying on implicit defaults.
    audio.enable = true;
    # Keep daemon socket-activated: zero idle bloat until clients connect.
    socketActivation = true;
    # Keep per-user service model; do not run a shared system daemon.
    systemWide = false;
    # Keep ALSA compatibility layer for native ALSA clients.
    alsa.enable = true;
    # Keep baseline lean: no 32-bit audio compatibility in shared profile.
    alsa.support32Bit = false;
    # Disable Pulse emulation for no-legacy baseline.
    pulse.enable = false;
    # Disable JACK emulation in shared baseline.
    jack.enable = false;
    # Keep network audio ports closed in shared baseline.
    raopOpenFirewall = false;

    wireplumber = {
      # WirePlumber policy/session manager for PipeWire.
      enable = true;
      # WirePlumber drop-in for ALSA speaker policy.
      extraConfig."95-high-quality-audio" = {
        # ALSA monitor defaults for the built-in speaker path.
        "monitor.alsa.properties" = {
          # Use ACP path for deterministic card/profile handling.
          "alsa.use-acp" = true;
        };
      };
    };

    # High-fidelity playback defaults:
    # - fixed fallback clock at 48 kHz
    # - wide allowed-rates set for transparent source-matched switching
    # - large quantum for playback stability at high sample rates
    # - max-quality resampling path
    extraConfig.pipewire."95-high-quality-audio" = {
      # PipeWire global clock and graph-level defaults.
      "context.properties" = {
        # Set the default graph sample rate to 48 kHz.
        "default.clock.rate" = 48000;
        # Allow transparent switching to source-native sample rates.
        "default.clock.allowed-rates" = [
          44100
          48000
          88200
          96000
          176400
          192000
          352800
          384000
        ];
        # Set default graph quantum (buffer size) in frames.
        "default.clock.quantum" = 2048;
        # Lower bound for graph quantum to protect low-latency paths.
        "default.clock.min-quantum" = 1024;
        # Upper bound for graph quantum to stabilize heavy/high-rate workloads.
        "default.clock.max-quantum" = 8192;
      };

      # Default per-stream processing properties.
      "stream.properties" = {
        # Use highest quality resampling profile.
        "resample.quality" = 14;
        # Normalize mixed channels to reduce clipping risk on speakers.
        "channelmix.normalize" = true;
      };
    };
  };

  # Explicitly disable PulseAudio daemon.
  services.pulseaudio.enable = false;

  # Realtime scheduling delegation for low-latency stable audio.
  security.rtkit.enable = true;
}
