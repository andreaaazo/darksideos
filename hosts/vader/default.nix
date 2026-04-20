# Compositor for vader.
# This file imports modules and declares host-specific overrides.
{
  imports = [
    # Disk layout
    ./disk.nix

    # Hardware
    ./hardware-configuration.nix

    # Core
    ../../shared-modules/core

    # Graphics
    ../../shared-modules/graphics

    # Hardware
    ../../shared-modules/hardware/audio.nix
    ../../shared-modules/hardware/bluetooth.nix
    ../../shared-modules/hardware/cpu-amd.nix
    ../../shared-modules/hardware/gpu-nvidia.nix

    # Home
    ../../shared-modules/home
    ../../shared-modules/impermanence
  ];

  sops = {
    # Host-specific encrypted secret bundle tracked in git.
    defaultSopsFile = ./secrets/vader.yaml;
  };

  # Keep controller in fast-connectable state to reduce reconnect latency at slight idle power cost.
  hardware.bluetooth.settings.General.FastConnectable = true;
}
