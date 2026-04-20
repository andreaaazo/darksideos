# Eval tests entry point.
{
  pkgs,
  lib,
  nixpkgs,
  home-manager,
  impermanence,
  sopsNix,
  zenBrowser,
}:
import ./suites-file {
  inherit
    pkgs
    lib
    nixpkgs
    home-manager
    impermanence
    sopsNix
    zenBrowser
    ;
}
// import ./suites-module {
  inherit
    pkgs
    lib
    nixpkgs
    home-manager
    impermanence
    sopsNix
    zenBrowser
    ;
}
// import ./suites-full {
  inherit
    pkgs
    lib
    nixpkgs
    home-manager
    impermanence
    sopsNix
    zenBrowser
    ;
}
