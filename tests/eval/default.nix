# Eval tests entry point.
{
  pkgs,
  lib,
  nixpkgs,
  home-manager,
  impermanence,
}: let
  testLib = import ./lib {inherit pkgs lib nixpkgs home-manager impermanence;};
in
  import ./suites {inherit pkgs testLib;}
