# Eval tests for shared-modules/core/nix.nix
# Verifies Nix daemon settings: flakes, GC, store optimization.
{
  pkgs,
  lib,
  testLib,
}:
let
  # Evaluate only the nix module in isolation
  config = testLib.getConfig {
    modules = [
      ../../../shared-modules/core/nix.nix
    ];
  };

  # Define assertions for this module
  assertions = [
    (testLib.assertContains {
      id = "nix-001";
      name = "flakes experimental feature enabled";
      inherit config;
      path = [
        "nix"
        "settings"
        "experimental-features"
      ];
      element = "flakes";
      severity = "critical";
      rationale = "Flakes required for entire workflow";
    })

    (testLib.assertContains {
      id = "nix-002";
      name = "nix-command experimental feature enabled";
      inherit config;
      path = [
        "nix"
        "settings"
        "experimental-features"
      ];
      element = "nix-command";
      severity = "critical";
      rationale = "nix build/nix flake CLI required for workflow";
    })

    (testLib.assertEnabled {
      id = "nix-003";
      name = "automatic GC enabled";
      inherit config;
      path = [
        "nix"
        "gc"
        "automatic"
      ];
      severity = "high";
      rationale = "Prevents disk from filling up with old store paths";
    })

    (testLib.assertEnabled {
      id = "nix-004";
      name = "store auto-optimization enabled";
      inherit config;
      path = [
        "nix"
        "settings"
        "auto-optimise-store"
      ];
      severity = "medium";
      rationale = "Hardlinks identical files to save disk space";
    })

    (testLib.assertString {
      id = "nix-005";
      name = "GC runs weekly";
      inherit config;
      path = [
        "nix"
        "gc"
        "dates"
      ];
      expected = "weekly";
      severity = "medium";
      rationale = "Regular GC schedule prevents disk bloat";
    })

    (testLib.assertContains {
      id = "nix-006";
      name = "root is trusted user";
      inherit config;
      path = [
        "nix"
        "settings"
        "trusted-users"
      ];
      element = "root";
      severity = "high";
      rationale = "Required for binary cache operations";
    })

    (testLib.assertContains {
      id = "nix-007";
      name = "wheel group is trusted";
      inherit config;
      path = [
        "nix"
        "settings"
        "trusted-users"
      ];
      element = "@wheel";
      severity = "high";
      rationale = "Allows sudo users to use Cachix";
    })

    (testLib.assertEnabled {
      id = "nix-008";
      name = "unfree packages allowed";
      inherit config;
      path = [
        "nixpkgs"
        "config"
        "allowUnfree"
      ];
      severity = "high";
      rationale = "Required for NVIDIA drivers and firmware blobs";
    })
  ];
in
pkgs.runCommand "eval-core-nix" { } (
  testLib.mkCheckScript {
    name = "core/nix";
    assertionResults = assertions;
  }
)
