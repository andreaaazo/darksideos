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
  };

  # Explicitly disable PulseAudio daemon.
  services.pulseaudio.enable = false;

  # Realtime scheduling delegation for low-latency stable audio.
  security.rtkit.enable = true;
}
