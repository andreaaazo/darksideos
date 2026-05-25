# Closure size budget for the shared-modules full stack composition.
# Mirrors the module list of vm/suites-full/stack-shared.nix so the budget
# tracks the integrated shared-modules surface, not a single host.
{
  pkgs,
  lib,
  nixpkgs,
  home-manager,
  impermanence,
  sopsNix,
  zenBrowser,
}: let
  testLib = import ../shared-modules/eval/lib {
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

  closureBudget = import ../lib/nix/closure-budget.nix {inherit pkgs lib;};

  stackBudgetMiB = 10240;

  stack = testLib.evalSharedModule {
    extraModules = [
      testLib.hmModule
      testLib.impermanenceModule
    ];
    modules = [
      ../../shared-modules/core
      ../../shared-modules/graphics
      ../../shared-modules/hardware/audio.nix
      ../../shared-modules/hardware/bluetooth.nix
      ../../shared-modules/hardware/cpu-intel.nix
      ../../shared-modules/hardware/gpu-nvidia.nix
      ../../shared-modules/impermanence
      ../../shared-modules/home
      ({lib, ...}: {
        users.users = {
          root.hashedPassword = lib.mkForce "!";
          andrea = {
            isNormalUser = true;
            home = "/home/andrea";
            hashedPassword = "!";
          };
        };
        nixpkgs.config.allowUnfree = true;
        hardware.nvidia.open = lib.mkForce false;
      })
    ];
  };
in
  closureBudget.mkClosureBudgetCheck {
    id = "budget-stack-shared-closure";
    name = "Shared stack closure stays within ${toString stackBudgetMiB} MiB";
    target = stack.config.system.build.toplevel;
    maxBytes = stackBudgetMiB * 1024 * 1024;
    severity = "high";
    rationale = "Shared-modules baseline must not silently bloat across refactors.";
  }
