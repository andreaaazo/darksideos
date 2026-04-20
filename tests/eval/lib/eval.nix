# Evaluation utilities for testing shared modules in isolation.
# Machine-agnostic: never references hosts, only shared-modules.
{
  nixpkgs,
  home-manager,
  impermanence,
  sopsNix,
  zenBrowser,
}: rec {
  # SOPS-Nix module for tests that evaluate sops.* options.
  sopsModule = sopsNix.nixosModules.sops;

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
  }: let
    # Default stubs for common specialArgs used across shared-modules
    defaultStubs = {
      hostName = "test-host";
      stateVersion = "25.11";
      # Pass zenBrowser input to modules that import external Zen Browser Home Manager module.
      inherit zenBrowser;
    };

    # Merge default stubs with caller-provided stubs
    finalStubs = defaultStubs // stubs;
  in
    nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = finalStubs;
      modules = [sopsModule] ++ extraModules ++ modules;
    };

  # Extracts config from evaluated modules.
  # Convenience wrapper for evalSharedModule that returns only config.
  getConfig = args: (evalSharedModule args).config;

  # Home-manager NixOS module for tests that need it.
  hmModule = home-manager.nixosModules.home-manager;

  # Impermanence NixOS module for tests that need it.
  impermanenceModule = impermanence.nixosModules.impermanence;
}
