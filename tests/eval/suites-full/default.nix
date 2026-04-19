# Eval suites aggregator for full-stack integration tests.
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
  eval-stack-shared = import ./stack-shared.nix {inherit pkgs testLib;};
}
