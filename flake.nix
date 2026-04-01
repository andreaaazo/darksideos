{
  description = "DarksideOS - NixOS infrastructure";

  inputs = {
    # NixPkgs source of main packages on rolling release channel
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    # Home Manager for user configuration management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Disko to manage disk partitions and filesystems declaratively
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Impermanence for managing ephemeral system state
    impermanence = {
      url = "github:nix-community/impermanence";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      disko,
      impermanence,
      ...
    }:
    let
      # Shared modules for every host configuration
      commonModules = [
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
        home-manager.nixosModules.home-manager
      ];
    in
    {
      nixosConfigurations = {
        starkiller = nixpkgs.lib.nixosSystem {
          # Linux 64-bit system
          system = "x86_64-linux";
          # Pass arguments to modules for use in configuration
          specialArgs = {
            hostName = "starkiller";
            stateVersion = "25.11";
          };
          modules = commonModules ++ [
            ./hosts/starkiller
          ];
        };

        vader = nixpkgs.lib.nixosSystem {
          # Linux 64-bit system
          system = "x86_64-linux";
          # Pass arguments to modules for use in configuration
          specialArgs = {
            hostName = "vader";
            stateVersion = "25.11";
          };
          modules = commonModules ++ [
            ./hosts/vader
          ];
        };
      };
    };
}
