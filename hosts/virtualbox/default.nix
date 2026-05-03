# Compositor for virtualbox.
# This file imports modules and declares host-specific overrides.
{
    imports = [
        # Host-specific
        ./disk.nix
        ./hardware-configuration.nix

        # Modules
        ../../shared-modules/core
        ../../shared-modules/graphics
        ../../shared-modules/home
        ../../shared-modules/impermanence
    ];


    sops = {
    # Host-specific encrypted secret bundle tracked in git.
    defaultSopsFile = ./secrets/virtualbox.yaml;
  };

}