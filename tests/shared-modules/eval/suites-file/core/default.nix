# Eval suites for shared-modules/core/*
{
  pkgs,
  testLib,
}: {
  eval-core-boot = import ./boot.nix {inherit pkgs testLib;};
  eval-core-locale = import ./locale.nix {inherit pkgs testLib;};
  eval-core-networking = import ./networking.nix {inherit pkgs testLib;};
  eval-core-nix = import ./nix.nix {inherit pkgs testLib;};
  eval-core-secrets = import ./secrets.nix {inherit pkgs testLib;};
  eval-core-users = import ./users.nix {inherit pkgs testLib;};
}
