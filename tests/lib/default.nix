# Test library entry point.
# Re-exports eval and assertion utilities.
{ pkgs, lib, nixpkgs }:
let
  eval = import ./eval.nix { inherit pkgs lib nixpkgs; };
  assertions = import ./assertions.nix { inherit lib; };
in
{
  inherit (eval) evalSharedModule getConfig;
  inherit (assertions)
    mkResult
    formatFailure
    assertEqual
    assertEnabled
    assertDisabled
    assertContains
    assertString
    runAssertions
    mkCheckScript
    ;
}
