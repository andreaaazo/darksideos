# Closure-size budget for the installer ISO image.
{
  pkgs,
  lib,
  self,
  system,
}: let
  closureBudget = import ../lib/nix/closure-budget.nix {inherit pkgs lib;};
  isoBudgetMiB = 3072;
in
  closureBudget.mkClosureBudgetCheck {
    id = "budget-iso-closure";
    name = "Installer ISO closure stays within ${toString isoBudgetMiB} MiB";
    target = self.packages.${system}.darksideos-installer-iso;
    maxBytes = isoBudgetMiB * 1024 * 1024;
    severity = "high";
    rationale = "Installer ISO bloat slows downloads, USB writes, and CI runtime. Bump only with measurement.";
  }
