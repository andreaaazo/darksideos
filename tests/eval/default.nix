# Eval tests entry point.
{
  pkgs,
  lib,
  nixpkgs,
  home-manager,
  impermanence,
  zenBrowser,
}: let
in
  (import ./suites-file {
    inherit
      pkgs
      lib
      nixpkgs
      home-manager
      impermanence
      zenBrowser
      ;
  })
  // (import ./suites-module {
    inherit
      pkgs
      lib
      nixpkgs
      home-manager
      impermanence
      zenBrowser
      ;
  })
  // (import ./suites-full {
    inherit
      pkgs
      lib
      nixpkgs
      home-manager
      impermanence
      zenBrowser
      ;
  })
