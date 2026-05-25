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

    # Minimal live ISO modules for the custom DarksideOS installer.
    installerModules = [
      "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      ./iso
    ];

    # Host configurations are discovered from hosts/<hostname>/default.nix.
    hostEntries = builtins.readDir ./hosts;
    hostNames =
      builtins.filter
      (
        hostName:
          hostEntries.${hostName}
          == "directory"
          && builtins.pathExists (./hosts + "/${hostName}/default.nix")
      )
      (builtins.attrNames hostEntries);

    mkHostConfiguration = hostName:
      nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = {
          inherit hostName;
          # Expose zenBrowser input to shared modules that import external Home Manager modules.
          inherit zenBrowser;
        };
        modules =
          commonModules
          ++ [
            (./hosts + "/${hostName}")
          ];
      };

    discoveredHostConfigurations =
      builtins.listToAttrs
      (builtins.map
        (hostName: {
          name = hostName;
          value = mkHostConfiguration hostName;
        })
        hostNames);

    optionalImport = path: args:
      if builtins.pathExists path
      then import path args
      else {};

    sharedModuleChecks = optionalImport ./tests/shared-modules/check-code {
      pkgs = pkgsLinux;
      inherit self;
      system = linuxSystem;
    };

    isoStaticChecks = optionalImport ./tests/iso/static {
      pkgs = pkgsLinux;
      inherit self;
      system = linuxSystem;
    };

    isoUnitTests = optionalImport ./tests/iso/unit {
      pkgs = pkgsLinux;
      inherit self;
    };

    sharedModuleUnitTests = optionalImport ./tests/shared-modules/unit {
      pkgs = pkgsLinux;
      inherit self;
    };

    isoIntegrationTests = optionalImport ./tests/iso/integration {
      pkgs = pkgsLinux;
      inherit self;
    };

    sharedModuleEvalTests = optionalImport ./tests/shared-modules/eval {
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

    isoEvalTests = optionalImport ./tests/iso/eval {
      pkgs = pkgsLinux;
      inherit self;
      inherit (nixpkgs) lib;
      system = linuxSystem;
    };

    # Closure-size budget checks. Heavy: they realize full system closures, so
    # they live outside the fast eval pipeline and run via `just check-budget`.
    budgetChecks = optionalImport ./tests/budget {
      pkgs = pkgsLinux;
      inherit (nixpkgs) lib;
      inherit
        self
        nixpkgs
        home-manager
        impermanence
        sopsNix
        zenBrowser
        ;
      system = linuxSystem;
    };

    sharedModuleVmTests = optionalImport ./tests/shared-modules/vm {
      pkgs = pkgsLinuxUnfree;
      inherit
        home-manager
        impermanence
        sopsNix
        zenBrowser
        ;
    };

    isoVmTests = optionalImport ./tests/iso/vm {
      pkgs = pkgsLinuxUnfree;
      inherit
        disko
        nixpkgs
        self
        ;
      inherit (nixpkgs) lib;
      system = linuxSystem;
    };
  in {
    # Flake checks: nix flake check
    # Local/CI checks run in Linux Docker runner.
    checks.${linuxSystem} = sharedModuleChecks // isoStaticChecks;

    # Unit tests: fast shell-level tests with no NixOS, Disko, SOPS, root, or VM dependency.
    unitTests.${linuxSystem} = isoUnitTests // sharedModuleUnitTests;

    # Integration tests: contract-level installer tests with destructive adapters stubbed.
    integrationTests.${linuxSystem} = isoIntegrationTests;

    # Eval tests: verify shared modules and the installer ISO produce correct configuration.
    # Linux-only (nixosSystem is Linux-only).
    evalTests.${linuxSystem} = sharedModuleEvalTests // isoEvalTests;

    # VM tests: boot a headless machine and validate runtime behavior.
    # Linux-only (runNixOSTest is Linux-only).
    vmTests.${linuxSystem} = sharedModuleVmTests // isoVmTests;

    # Closure-size budgets: heavy build checks, run via `just check-budget`.
    budgetChecks.${linuxSystem} = budgetChecks;

    packages.${linuxSystem}.darksideos-installer-iso =
      self.nixosConfigurations.darksideos-installer.config.system.build.isoImage;

    nixosConfigurations =
      discoveredHostConfigurations
      // {
        darksideos-installer = nixpkgs.lib.nixosSystem {
          system = linuxSystem;
          specialArgs = {
            inherit
              disko
              self
              ;
          };
          modules = installerModules;
        };
      };
  };
}
