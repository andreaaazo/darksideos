# Eval suites for shared-modules/home/*
{
  pkgs,
  testLib,
}:
(import ./modules {inherit pkgs testLib;})
// {
  eval-home-home = import ./home.nix {inherit pkgs testLib;};
}
