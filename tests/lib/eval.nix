# Evaluation utilities for testing shared modules in isolation.
# Machine-agnostic: never references hosts, only shared-modules.
{nixpkgs}: rec {
  # Evaluates a shared module using nixpkgs.lib.nixosSystem.
  # Returns the full NixOS config tree without building anything.
  #
  # Arguments:
  #   modules: list of modules to evaluate
  #   stubs: attribute set of specialArgs overrides
  #
  # Example:
  #   evalSharedModule {
  #     modules = [ ../../shared-modules/core ];
  #     stubs = { hostName = "test"; stateVersion = "25.11"; };
  #   }
  evalSharedModule = {
    modules,
    stubs ? {},
  }: let
    # Default stubs for common specialArgs used across shared-modules
    defaultStubs = {
      hostName = "test-host";
      stateVersion = "25.11";
    };

    # Merge default stubs with caller-provided stubs
    finalStubs = defaultStubs // stubs;
  in
    nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = finalStubs;
      inherit modules;
    };

  # Extracts config from evaluated modules.
  # Convenience wrapper for evalSharedModule that returns only config.
  getConfig = args: (evalSharedModule args).config;
}
