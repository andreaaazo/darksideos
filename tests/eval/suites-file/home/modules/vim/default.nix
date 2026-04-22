# Eval tests for shared-modules/home/modules/vim/default.nix.
{
  pkgs,
  testLib,
}:
import ./vim.nix {inherit pkgs testLib;}
