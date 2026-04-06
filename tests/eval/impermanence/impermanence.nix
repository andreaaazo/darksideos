# Eval tests for shared-modules/impermanence/impermanence.nix
# Verifies system-level persistence declarations.
#
# Note: impermanence has complex internal transformations that make
# testing individual directories difficult. We test the core settings
# and verify the directories list has the expected count.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.impermanenceModule];
    modules = [
      ../../../shared-modules/impermanence/impermanence.nix
    ];
  };

  persistConfig = config.environment.persistence."/persist";

  # Count directories and files from raw definitions
  dirCount = builtins.length persistConfig.directories;
  fileCount = builtins.length persistConfig.files;

  assertions = [
    (testLib.assertEnabled {
      id = "impermanence-001";
      name = "hideMounts enabled";
      inherit config;
      path = [
        "environment"
        "persistence"
        "/persist"
        "hideMounts"
      ];
      severity = "medium";
      rationale = "Hides bind mounts from df and file managers";
    })

    (testLib.mkResult {
      id = "impermanence-002";
      name = "Expected directories count";
      passed = dirCount == 7;
      expected = 7;
      actual = dirCount;
      severity = "critical";
      rationale = "7 directories: nixos, coredump, timers, NetworkManager (2), bluetooth, ssh";
    })

    (testLib.mkResult {
      id = "impermanence-003";
      name = "Expected files count";
      passed = fileCount == 1;
      expected = 1;
      actual = fileCount;
      severity = "critical";
      rationale = "1 file: machine-id";
    })
  ];
in
pkgs.runCommand "eval-impermanence" {} (
  testLib.mkCheckScript {
    name = "impermanence";
    assertionResults = assertions;
  }
)
