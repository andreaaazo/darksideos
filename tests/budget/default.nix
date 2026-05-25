# Closure-size budget checks.
# These realize (build) full system closures, so they are intentionally kept
# out of the fast eval pipeline and run through the dedicated opt-in entrypoint
# (scripts/repo/check-budget.sh / `just check-budget`).
{
  pkgs,
  lib,
  self,
  system,
  nixpkgs,
  home-manager,
  impermanence,
  sopsNix,
  zenBrowser,
}: let
  isoBudget = import ./iso.nix {inherit pkgs lib self system;};
  hostBudgets = import ./hosts.nix {inherit pkgs lib self;};
  stackBudget = import ./stack.nix {
    inherit
      pkgs
      lib
      nixpkgs
      home-manager
      impermanence
      sopsNix
      zenBrowser
      ;
  };
in
  {
    budget-iso-closure = isoBudget;
    budget-stack-shared-closure = stackBudget;
  }
  // hostBudgets
