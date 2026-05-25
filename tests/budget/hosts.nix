# Per-host closure size budgets.
# Enumerates every NixOS configuration in the flake (excluding the live
# installer image, which has its own budget) and produces one check per host.
{
  pkgs,
  lib,
  self,
}: let
  closureBudget = import ../lib/nix/closure-budget.nix {inherit pkgs lib;};

  hostBudgetMiB = 12288;
  maxBytes = hostBudgetMiB * 1024 * 1024;

  hostNames =
    builtins.filter
    (configurationName: configurationName != "darksideos-installer")
    (builtins.attrNames self.nixosConfigurations);
in
  builtins.listToAttrs (
    builtins.map
    (hostName: {
      name = "budget-host-${hostName}-closure";
      value = closureBudget.mkClosureBudgetCheck {
        id = "budget-host-${hostName}-closure";
        name = "Host ${hostName} closure stays within ${toString hostBudgetMiB} MiB";
        target = self.nixosConfigurations.${hostName}.config.system.build.toplevel;
        inherit maxBytes;
        severity = "high";
        rationale = "Per-host closure budget catches bloat before it ships and hits user disks.";
      };
    })
    hostNames
  )
