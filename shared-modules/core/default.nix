# Core configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{stateVersion, ...}: {
  # Import the baseline core modules shared by all hosts.
  imports = [
    ./boot.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./secrets.nix
    ./users.nix
  ];

  # System state version — do NOT change after install
  system.stateVersion = stateVersion;
}
