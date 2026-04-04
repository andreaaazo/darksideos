# Users configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{
  users = {
    # Disables passwd/useradd commands; users can only be created/modified declaratively in Nix (essential with impermanence, otherwise changes vanish on reboot).
    mutableUsers = false;

    users = {
      root = {
        # Locks root account entirely (the ! hash matches no password, forcing sudo-only access).
        hashedPassword = "!";
      };

      andrea = {
        # Creates a regular user with home directory, login shell, and UID in the normal range (1000+).
        isNormalUser = true;
        # Human-readable name shown in display managers and finger output.
        description = "Andrea";

        extraGroups = [
          "wheel" # Grants sudo privileges.
          "networkmanager" # Allows managing network connections without sudo.
          "video" # Grants direct GPU device access (required for Wayland compositors and GPU-accelerated apps).
        ];
        # Reads password hash from a file on the persistent volume
        # Generate with: nix-shell -p mkpasswd --run 'mkpasswd -m sha-512'
        # Store the hash in /persist/secrets/pc-password
        hashedPasswordFile = "/persist/secrets/pc-password";
      };
    };
  };

  security.sudo = {
    # Enables the sudo subsystem.
    enable = true;
    # Sudo requires the user's password (no passwordless escalation).
    wheelNeedsPassword = true;
    # Only wheel group members can execute sudo (non-wheel users can't even attempt it).
    execWheelOnly = true;
  };
}
