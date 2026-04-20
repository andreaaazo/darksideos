# Nix configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{
  # Allow unfree packages from nixpkgs (e.g. for firmware blobs, GPU drivers, etc.)
  nixpkgs.config.allowUnfree = true;

  # Nix daemon namespace (channels, settings, GC, and store optimization).
  nix = {
    # Disable legacy channel workflow (flakes-only).
    channel.enable = false;

    # Core Nix daemon runtime settings.
    settings = {
      # Enables nix build/nix flake CLI and flakes support (required for workflow)
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Build derivations in isolated sandboxes for stronger reproducibility and safety.
      sandbox = true;
      # Accept only signed substituter artifacts.
      require-sigs = true;
      # Automatically hardlinks identical files in /nix/store (saves disk space, especially with many generations)
      auto-optimise-store = true;
      # Parallelism and fail-fast behavior for faster, more predictable local builds.
      # Allow Nix to auto-detect local CPU core count.
      max-jobs = "auto";
      # Let each build use all detected cores unless derivation overrides it.
      cores = 0;
      # Disable fallback compilation from source when substitutes fail.
      fallback = false;
      # Allows root and sudo users to push to binary caches and use substituters.
      trusted-users = [
        "root"
        "@wheel"
      ];
      # Restrict daemon usage to privileged users only.
      allowed-users = [
        "root"
        "@wheel"
      ];
    };

    # Automatic garbage collection policy.
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

    # Scheduled Nix store deduplication policy.
    optimise = {
      # Periodic store deduplication in addition to write-time optimization.
      automatic = true;
      # Run store optimization weekly to keep deduplication cost predictable.
      dates = "weekly";
    };
  };

  # Disable package suggestion hook to reduce shell overhead and noise.
  programs.command-not-found.enable = false;
  # Keep NixOS manual out of shared baseline.
  documentation.nixos.enable = false;
}
