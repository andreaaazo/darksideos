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

    # SOPS-Nix for declarative secret decryption with age at activation/runtime.
    sopsNix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen Browser flake for declarative browser package and Home Manager integration.
    zenBrowser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    disko,
    impermanence,
    sopsNix,
    zenBrowser,
    ...
  }: let
    linuxSystem = "x86_64-linux";

    pkgsLinux = nixpkgs.legacyPackages.${linuxSystem};
    pkgsLinuxUnfree = import nixpkgs {
      system = linuxSystem;
      config.allowUnfree = true;
    };

    # Shared modules for every host configuration
    commonModules = [
      disko.nixosModules.disko
      impermanence.nixosModules.impermanence
      sopsNix.nixosModules.sops
      home-manager.nixosModules.home-manager
    ];
  in {
    # Flake checks: nix flake check
    # Local/CI checks run in Linux Docker runner.
    checks.${linuxSystem} = import ./tests/checks {
      pkgs = pkgsLinux;
      inherit self;
    };

    # Eval tests: verify shared modules produce correct configuration.
    # Linux-only (nixosSystem is Linux-only).
    evalTests.${linuxSystem} = import ./tests/eval {
      pkgs = pkgsLinux;
      inherit (nixpkgs) lib;
      inherit
        nixpkgs
        home-manager
        impermanence
        sopsNix
        zenBrowser
        ;
    };

    # VM tests: boot a headless machine and validate runtime behavior.
    # Linux-only (runNixOSTest is Linux-only).
    vmTests.${linuxSystem} = import ./tests/vm {
      pkgs = pkgsLinuxUnfree;
      inherit
        home-manager
        impermanence
        sopsNix
        zenBrowser
        ;
    };

    nixosConfigurations = {
      starkiller = nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = {
          hostName = "starkiller";
          stateVersion = "25.11";
          inherit zenBrowser;
        };
        modules =
          commonModules
          ++ [
            ./hosts/starkiller
          ];
      };

      vader = nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = {
          hostName = "vader";
          stateVersion = "25.11";
          inherit zenBrowser;
        };
        modules =
          commonModules
          ++ [
            ./hosts/vader
          ];
      };
    };
  };
}
