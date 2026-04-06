# Home configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{
  imports = [
    ./home.nix
  ];
}
