# VM tests entry point.
# Exposes only runnable VM suites.
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
  import ./suites {
    inherit vmLib;
  }
