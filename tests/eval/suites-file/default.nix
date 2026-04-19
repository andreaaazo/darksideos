# Eval suites aggregator for file-level tests.
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
in
  (import ./core {inherit pkgs testLib;})
  // (import ./graphics {inherit pkgs testLib;})
  // (import ./hardware {inherit pkgs testLib;})
  // (import ./home {inherit pkgs testLib;})
  // (import ./impermanence {inherit pkgs testLib;})
