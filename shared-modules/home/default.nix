# Home configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{
  # Import Home Manager integration module for all hosts.
  imports = [
    ./home.nix
  ];
}
