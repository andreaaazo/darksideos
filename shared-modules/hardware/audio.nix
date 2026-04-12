# Minimal PipeWire audio stack.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{
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
    # WirePlumber policy/session manager for PipeWire.
    wireplumber.enable = true;

    # High-fidelity playback defaults:
    # - fixed fallback clock at 48 kHz
    # - wide allowed-rates set for transparent source-matched switching
    # - large quantum for playback stability at high sample rates
    # - max-quality resampling path
    extraConfig.pipewire."95-high-quality-audio" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
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
        "default.clock.quantum" = 2048;
        "default.clock.min-quantum" = 1024;
        "default.clock.max-quantum" = 8192;
      };

      "stream.properties" = {
        "resample.quality" = 15;
      };
    };
  };

  # Explicitly disable PulseAudio daemon.
  services.pulseaudio.enable = false;

  # Realtime scheduling delegation for low-latency stable audio.
  security.rtkit.enable = true;
}
