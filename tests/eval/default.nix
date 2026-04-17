# Eval tests entry point.
{
  pkgs,
  lib,
  nixpkgs,
  home-manager,
  impermanence,
  zenBrowser,
}: let
  testLib = import ./lib {
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
  import ./suites {inherit pkgs testLib;}
