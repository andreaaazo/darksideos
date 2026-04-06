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
      self,
      nixpkgs,
      home-manager,
      disko,
      impermanence,
      ...
    }:
    let
      linuxSystem = "x86_64-linux";
      darwinSystem = "x86_64-darwin";

      pkgsLinux = nixpkgs.legacyPackages.${linuxSystem};
      pkgsDarwin = nixpkgs.legacyPackages.${darwinSystem};

      # Shared modules for every host configuration
      commonModules = [
        disko.nixosModules.disko
        impermanence.nixosModules.impermanence
        home-manager.nixosModules.home-manager
      ];
    in
    {
      # Development shell: nix develop
      devShells.${linuxSystem}.default = import ./devshell.nix { pkgs = pkgsLinux; };
      devShells.${darwinSystem}.default = import ./devshell.nix { pkgs = pkgsDarwin; };

      # Flake checks: nix flake check
      # Static analysis (formatting, linting, deadcode) runs on both Linux and Darwin.
      checks.${linuxSystem} = import ./checks.nix {
        pkgs = pkgsLinux;
        inherit self;
      };
      checks.${darwinSystem} = import ./checks.nix {
        pkgs = pkgsDarwin;
        inherit self;
      };

      # Eval tests: verify shared modules produce correct configuration.
      # Linux-only (nixosSystem is Linux-only).
      evalTests.${linuxSystem} = import ./tests {
        pkgs = pkgsLinux;
        inherit (nixpkgs) lib;
        inherit nixpkgs;
      };

      nixosConfigurations = {
        starkiller = nixpkgs.lib.nixosSystem {
          system = linuxSystem;
          specialArgs = {
            hostName = "starkiller";
            stateVersion = "25.11";
          };
          modules = commonModules ++ [
            ./hosts/starkiller
          ];
        };

        # vader = nixpkgs.lib.nixosSystem {
        #   system = linuxSystem;
        #   specialArgs = {
        #     hostName = "vader";
        #     stateVersion = "25.11";
        #   };
        #   modules = commonModules ++ [
        #     ./hosts/vader
        #   ];
        # };
      };
    };
}
