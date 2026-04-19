# Users configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{
  # User management namespace (accounts, credentials, and account mutability policy).
  users = {
    # Disables passwd/useradd commands; users can only be created/modified declaratively in Nix (essential with impermanence, otherwise changes vanish on reboot).
    mutableUsers = false;

    # Declarative user definitions.
    users = {
      # Built-in superuser account policy.
      root = {
        # Locks root account entirely (the ! hash matches no password, forcing sudo-only access).
        hashedPassword = "!";
      };

      # Primary human user account for this workstation profile.
      andrea = {
        # Creates a regular user with home directory, login shell, and UID in the normal range (1000+).
        isNormalUser = true;
        # Keep UID stable across rebuilds and impermanence resets.
        uid = 1000;
        # Human-readable name shown in display managers and finger output.
        description = "Andrea";
        # Restrict home directory access to the account owner.
        homeMode = "0700";

        # Grant supplemental groups used by this account.
        extraGroups = [
          "wheel" # Grants sudo privileges.
        ];
        # Reads password hash from a file on the persistent volume
        # Generate with: nix-shell -p mkpasswd --run 'mkpasswd -m sha-512'
        # Store the hash in /persist/secrets/pc-password
        hashedPasswordFile = "/persist/secrets/pc-password";
      };
    };
  };

  # Privilege escalation policy namespace.
  security.sudo = {
    # Enables the sudo subsystem.
    enable = true;
    # Sudo requires the user's password (no passwordless escalation).
    wheelNeedsPassword = true;
    # Only wheel group members can execute sudo (non-wheel users can't even attempt it).
    execWheelOnly = true;
    # Harden sudo behavior for privacy and strict privilege boundaries.
    extraConfig = ''
      Defaults use_pty
      Defaults timestamp_timeout=0
      Defaults passwd_tries=3
      Defaults env_reset
      Defaults umask=0077
    '';
  };

  # Restrict `su` command usage to wheel members only.
  security.pam.services.su = {
    # Only wheel users may use su.
    requireWheel = true;
  };
}
