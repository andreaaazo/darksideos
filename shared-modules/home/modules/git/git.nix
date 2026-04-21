{
  config,
  lib,
  pkgs,
  ...
}: let
  gitSshKeyPath = "/run/secrets/andrea-git-ssh-key";
in {
  # Git runtime key stays outside the Nix store and is materialized before Home Manager reads it.
  sops.secrets = lib.mkIf (config.sops.defaultSopsFile != null) {
    # Single private key used for GitHub transport and SSH commit signing; register its public key on GitHub for both roles.
    andrea-git-ssh-key = {
      owner = "andrea";
      group = "users";
      mode = "0400";
    };
  };

  # Configure Git through Home Manager so binary and dotfile policy are generated from one source.
  home-manager.users.andrea.programs.git = {
    enable = true;
    package = pkgs.git;

    settings = {
      user = {
        # Identity is explicit so commits stay reproducible across hosts and shells.
        name = "Andrea";
        # Email is declared here instead of relying on mutable host-local git config.
        email = "zorzi.andrea@outlook.com";
        # Same host key signs commits and authenticates to GitHub, reducing secret surface.
        signingKey = gitSshKeyPath;
      };

      gpg = {
        # Use SSH signatures to match the repository verified-commit workflow.
        format = "ssh";
      };

      init = {
        # New repositories should use the same default branch expected by the project workflow.
        defaultBranch = "main";
      };

      core = {
        # Keep line endings stable on Linux and avoid platform-dependent checkout rewrites.
        autocrlf = false;
        # Use the baseline editor already present in the minimal Home profile.
        editor = "vim";
      };

      pull = {
        # Rebase local commits by default to keep trunk-oriented history linear.
        rebase = true;
      };

      rebase = {
        # Preserve local dirty state while rebasing without requiring manual stash choreography.
        autoStash = true;
        # Move dependent local branches when their upstream commits are rewritten.
        updateRefs = true;
      };

      fetch = {
        # Remove deleted remote branches locally so refs do not drift.
        prune = true;
        # Remove deleted remote tags locally for the same deterministic ref view.
        pruneTags = true;
      };

      push = {
        # Create upstream tracking automatically on first push of a new branch.
        autoSetupRemote = true;
        # Push annotated tags reachable from pushed commits without pushing unrelated tags.
        followTags = true;
      };

      rerere = {
        # Reuse recorded conflict resolutions, making repeated rebases less error-prone.
        enabled = true;
      };

      diff = {
        # Histogram gives more stable hunks for moved or refactored Nix blocks.
        algorithm = "histogram";
        # Highlight moved lines so reviews can distinguish movement from edits.
        colorMoved = "default";
      };

      merge = {
        # zdiff3 keeps base context visible when resolving conflicts.
        conflictStyle = "zdiff3";
      };

      branch = {
        # Show most recently touched branches first in branch listings.
        sort = "-committerdate";
      };

      tag = {
        # Sort version-like tags naturally instead of lexicographically.
        sort = "version:refname";
      };

      commit = {
        # Sign every commit by default so unsigned commits fail locally before CI/review.
        gpgSign = true;
        # Include the diff in commit-message editing for local verification before signing.
        verbose = true;
      };

      protocol = {
        # Protocol v2 reduces negotiation overhead for modern Git servers.
        version = 2;
      };
    };
  };

  # Route GitHub SSH auth through the standard runtime secret instead of impermanent ~/.ssh state.
  home-manager.users.andrea.programs.ssh = {
    enable = true;
    # Avoid Home Manager implicit SSH defaults so future updates cannot silently change client behavior.
    enableDefaultConfig = false;
    matchBlocks."github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = gitSshKeyPath;
      identitiesOnly = true;
    };
  };
}
