# Nix configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{
  nix = {
    # Allow unfree packages from nixpkgs (e.g. for firmware blobs, GPU drivers, etc.)
    nixpkgs.config.allowUnfree = true;

    settings = {
      # Enables nix build/nix flake CLI and flakes support (required for workflow)
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Automatically hardlinks identical files in /nix/store (saves disk space, especially with many generations)
      auto-optimise-store = true;
      # Allows root and sudo users to push to binary caches and use substituters (required for Cachix CI workflow)
      trusted-users = [
        "root"
        "@wheel"
      ];
    };

    gc = {
      # Enables scheduled automatic garbage collection of unused store paths.
      automatic = true;
      # Run garbage collection once per week via systemd timer.
      dates = "weekly";
      # Remove store paths not referenced by any generation newer than 7 days (keeps a week of rollback).
      options = "--delete-older-than 7d";
    };
  };
}
