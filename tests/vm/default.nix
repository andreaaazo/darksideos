# VM tests entry point.
# Exposes runnable VM test outputs composed from file-level and full-stack suites.
{
  pkgs,
  home-manager,
  impermanence,
}: let
  vmLib = import ./lib {
    inherit
      pkgs
      home-manager
      impermanence
      ;
  };
in
  (import ./suites-file {inherit vmLib;})
  // (import ./suites-full {inherit vmLib;})
