# Test library entry point.
# Re-exports eval and assertion utilities.
{
  pkgs,
  lib,
  nixpkgs,
  home-manager,
  impermanence,
  sopsNix,
  zenBrowser,
}: let
  evalLib = import ./eval.nix {
    inherit
      nixpkgs
      home-manager
      impermanence
      sopsNix
      zenBrowser
      ;
  };
  assertionsLib = import ./assertions.nix {inherit lib;};
in {
  inherit pkgs;

  # Eval/runtime helpers (module evaluation + shared fixtures).
  inherit
    (evalLib)
    evalSharedModule
    getConfig
    hmModule
    impermanenceModule
    sopsModule
    getEnabledSystemServices
    ;

  # Assertion helpers (pure result primitives + check script builder).
  inherit
    (assertionsLib)
    mkResult
    formatFailure
    assertEqual
    assertEnabled
    assertDisabled
    assertContains
    assertAnyContainsStringified
    assertAnyHasSuffixStringified
    assertAnyContainsAllStringified
    assertString
    assertStringContains
    runAssertions
    mkCheckScript
    ;
}
