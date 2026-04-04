# Home Manager entry point, integrated as a NixOS module.
# This file configures HM itself and imports user-level modules.
# All user packages and dotfiles go in home/modules/, not here.
{config, ...}: {
  home-manager = {
    # Home Manager uses the system's nixpkgs instance instead of evaluating its own (one nixpkgs eval, faster builds, no version mismatch).
    useGlobalPkgs = true;
    # Installs user packages to /etc/profiles/per-user/andrea instead of ~/.nix-profile (avoids conflicts with system packages, works better with impermanence).
    useUserPackages = true;

    users.andrea = {
      home = {
        #  Tells HM which UNIX user this config belongs to (must match the user declared in users.nix).
        username = "andrea";
        # The absolute path to the user's home directory (HM needs this to know where to place dotfiles and symlinks).
        homeDirectory = "/home/andrea";
        # Reads the system-level stateVersion so HM uses the same migration baseline.
        inherit (config.system) stateVersion;
      };

      imports = [
        # Loads user-level modules (shell, git, editor, etc.) from the modules/ subdirectory.
        ./modules
      ];
    };
  };
}
