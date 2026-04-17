# VM tests entry point.
# Exposes only runnable VM suites.
{
  pkgs,
  home-manager,
  impermanence,
  zenBrowser,
}: let
  vmLib = import ./lib {
    inherit
      pkgs
      home-manager
      impermanence
      zenBrowser
      ;
  };
in
  import ./suites {
    inherit vmLib;
  }
