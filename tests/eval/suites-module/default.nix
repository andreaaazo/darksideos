# Eval suites aggregator for module-integration tests.
{
  pkgs,
  lib,
  nixpkgs,
  home-manager,
  impermanence,
  zenBrowser,
}: let
  testLib = import ../lib {
    inherit
      pkgs
      lib
      nixpkgs
      home-manager
      impermanence
      zenBrowser
      ;
  };
in {
  eval-module-core = import ./module-core.nix {inherit pkgs testLib;};
  eval-module-graphics = import ./module-graphics.nix {inherit pkgs testLib;};
  eval-module-hardware = import ./module-hardware.nix {inherit pkgs testLib;};
  eval-module-home = import ./module-home.nix {inherit pkgs testLib;};
  eval-module-impermanence = import ./module-impermanence.nix {inherit pkgs testLib;};
}
