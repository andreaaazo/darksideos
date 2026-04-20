# Eval suites aggregator for full-stack integration tests.
{
  pkgs,
  lib,
  nixpkgs,
  home-manager,
  impermanence,
  sopsNix,
  zenBrowser,
}: let
  testLib = import ../lib {
    inherit
      pkgs
      lib
      nixpkgs
      home-manager
      impermanence
      sopsNix
      zenBrowser
      ;
  };
in {
  eval-stack-shared = import ./stack-shared.nix {inherit pkgs testLib;};
}
