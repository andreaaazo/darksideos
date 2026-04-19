# Fonts configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{
  # Import the shared font stack and fontconfig policy.
  imports = [
    ./fonts.nix
  ];
}
