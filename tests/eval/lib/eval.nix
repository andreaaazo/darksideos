# Evaluation utilities for testing shared modules in isolation.
# Machine-agnostic: never references hosts, only shared-modules.
{
  nixpkgs,
  home-manager,
  impermanence,
  sopsNix,
  zenBrowser,
}: let
  # External NixOS modules consumed by eval test harnesses.
  externalModules = {
    homeManager = home-manager.nixosModules.home-manager;
    inherit (impermanence.nixosModules) impermanence;
    inherit (sopsNix.nixosModules) sops;
  };

  # Default specialArgs for shared-module evaluation.
  # NOTE: zenBrowser is a flake input value (not a NixOS module), so it must be
  # passed through specialArgs for modules that reference it in imports/config.
  defaultSpecialArgs = {
    hostName = "test-host";
    stateVersion = "25.11";
    inherit zenBrowser;
  };

  # Merge caller-provided stubs over deterministic defaults.
  mkSpecialArgs = stubs: defaultSpecialArgs // stubs;
in rec {
  # Home-manager NixOS module for tests that need it.
  hmModule = externalModules.homeManager;

  # Impermanence NixOS module for tests that need it.
  impermanenceModule = externalModules.impermanence;

  # SOPS-Nix module for tests that evaluate sops.* options.
  sopsModule = externalModules.sops;

  # Evaluates a shared module using nixpkgs.lib.nixosSystem.
  # Returns the full NixOS config tree without building anything.
  #
  # Arguments:
  #   modules: list of modules to evaluate
  #   stubs: attribute set of specialArgs overrides
  #   extraModules: additional NixOS modules (e.g., home-manager)
  #
  # Example:
  #   evalSharedModule {
  #     modules = [ ../../shared-modules/core ];
  #     stubs = { hostName = "test"; stateVersion = "25.11"; };
  #   }
  #
  # Includes sopsModule by default so file-level tests can evaluate shared secrets options.
  evalSharedModule = {
    modules,
    stubs ? {},
    extraModules ? [],
  }:
    nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = mkSpecialArgs stubs;
      modules = [sopsModule] ++ extraModules ++ modules;
    };

  # Extracts config from evaluated modules.
  # Convenience wrapper for evalSharedModule that returns only config.
  getConfig = args: (evalSharedModule args).config;

  # Returns enabled system service names for full-stack assertions.
  getEnabledSystemServices = config:
    builtins.sort builtins.lessThan
    (builtins.filter
      (name: let
        svc = config.systemd.services.${name};
      in
        (builtins.length (svc.wantedBy or []))
        > 0
        || (builtins.length (svc.requiredBy or [])) > 0
        || (builtins.length (svc.upheldBy or [])) > 0)
      (builtins.attrNames config.systemd.services));
}
