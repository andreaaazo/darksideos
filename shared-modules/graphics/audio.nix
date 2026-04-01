# Pipewire audio stack with ALSA/PulseAudio compatibility.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{ ... }:
{
  services.pipewire = {
    # Installs Pipewire and starts the audio/video daemon that replaces PulseAudio and ALSA.
    enable = true;
    # Adds ALSA compatibility layer so apps using raw ALSA API (games, low-level audio tools) output through Pipewire.
    alsa.enable = true;
    # Installs 32-bit ALSA libraries for 32-bit apps (Steam, Wine).
    alsa.support32Bit = true;
    # Adds PulseAudio compatibility layer so apps using PulseAudio API (Firefox, Discord, most desktop apps) output through Pipewire.
    pulse.enable = true;
    # Starts WirePlumber, the session manager that handles audio device routing, policy, and hotplug for Pipewire.
    wireplumber.enable = true; # Session manager for Pipewire
  };

  # Explicitly disables PulseAudio daemon to prevent conflict with Pipewire's PulseAudio compatibility layer.
  services.pulseaudio.enable = false;

  # Enables RealtimeKit, a D-Bus service that grants real-time scheduling priority to Pipewire (prevents audio crackling and latency).
  security.rtkit.enable = true;
}
