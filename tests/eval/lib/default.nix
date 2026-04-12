# Test library entry point.
# Re-exports eval and assertion utilities.
{
  pkgs,
  lib,
  nixpkgs,
  home-manager,
  impermanence,
}: let
  eval = import ./eval.nix {inherit nixpkgs home-manager impermanence;};
  assertions = import ./assertions.nix {inherit lib;};
in {
  inherit pkgs;
  inherit (eval) evalSharedModule getConfig hmModule impermanenceModule;
  inherit
    (assertions)
    mkResult
    formatFailure
    assertEqual
    assertEnabled
    assertDisabled
    assertContains
    assertString
    assertStringContains
    runAssertions
    mkCheckScript
    ;
}
