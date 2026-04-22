# Home configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{
  # Import Home Manager integration and the standalone Home module collection.
  imports = [
    ./home.nix
    ./modules
  ];
}
