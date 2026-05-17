# Eval suites for shared-modules/impermanence/*
{
  pkgs,
  testLib,
}: {
  eval-impermanence = import ./impermanence.nix {inherit pkgs testLib;};
}
