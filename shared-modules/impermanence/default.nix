# Home configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{
  # Import the shared impermanence persistence policy.
  imports = [
    ./impermanence.nix
  ];
}
