# Eval tests for shared-modules/home/modules/git/default.nix.
{
  pkgs,
  testLib,
}:
import ./git.nix {inherit pkgs testLib;}
