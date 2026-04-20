# VM tests entry point.
# Exposes runnable VM test outputs composed from file-level, module-level, and full-stack suites.
{
  pkgs,
  home-manager,
  impermanence,
  sopsNix,
  zenBrowser,
}:
(import ./suites-file {
  inherit
    pkgs
    home-manager
    impermanence
    sopsNix
    zenBrowser
    ;
})
// (import ./suites-module {
  inherit
    pkgs
    home-manager
    impermanence
    sopsNix
    zenBrowser
    ;
})
// (import ./suites-full {
  inherit
    pkgs
    home-manager
    impermanence
    sopsNix
    zenBrowser
    ;
})
