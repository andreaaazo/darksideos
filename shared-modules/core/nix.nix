# Nix configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{
  # Allow unfree packages from nixpkgs (e.g. for firmware blobs, GPU drivers, etc.)
  nixpkgs.config.allowUnfree = true;

  nix = {
    # Disable legacy channel workflow (flakes-only).
    channel.enable = false;

    settings = {
      # Enables nix build/nix flake CLI and flakes support (required for workflow)
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Automatically hardlinks identical files in /nix/store (saves disk space, especially with many generations)
      auto-optimise-store = true;
      # Parallelism and fail-fast behavior for faster, more predictable local builds.
      max-jobs = "auto";
      cores = 0;
      fallback = false;
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
      # Catch up missed GC runs after downtime.
      persistent = true;
      # Remove store paths not referenced by any generation newer than 7 days (keeps a week of rollback).
      options = "--delete-older-than 7d";
    };

    optimise = {
      # Periodic store deduplication in addition to write-time optimization.
      automatic = true;
      dates = "weekly";
    };
  };
}
