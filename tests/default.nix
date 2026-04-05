# Eval test aggregator.
# Collects all eval tests and exposes them as flake checks.
# Structure mirrors shared-modules/ for discoverability.
#
# Usage in flake.nix:
#   checks.x86_64-linux = import ./tests { inherit pkgs lib nixpkgs; };
{
  pkgs,
  lib,
  nixpkgs,
}:
let
  testLib = import ./lib { inherit pkgs lib nixpkgs; };
in
{
  # core/
  eval-core-boot = import ./eval/core/boot.nix { inherit pkgs lib testLib; };
  eval-core-locale = import ./eval/core/locale.nix { inherit pkgs lib testLib; };
  eval-core-networking = import ./eval/core/networking.nix { inherit pkgs lib testLib; };
  eval-core-nix = import ./eval/core/nix.nix { inherit pkgs lib testLib; };
  eval-core-users = import ./eval/core/users.nix { inherit pkgs lib testLib; };
}
