# Eval tests for shared-modules/impermanence/impermanence.nix
# Verifies minimal system-level persistence declarations.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.impermanenceModule];
    modules = [
      ../../../../shared-modules/impermanence/impermanence.nix
    ];
  };

  persistConfig = config.environment.persistence."/persist";
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
      name = "Expected minimal directories count";
      passed = dirCount == 5;
      expected = 5;
      actual = dirCount;
      severity = "critical";
      rationale = "Minimal baseline keeps only essential system state paths";
    })

    (testLib.mkResult {
      id = "impermanence-003";
      name = "Expected files count";
      passed = fileCount == 2;
      expected = 2;
      actual = fileCount;
      severity = "critical";
      rationale = "2 files: machine-id and random-seed";
    })
  ];
in
  pkgs.runCommand "eval-impermanence" {} (
    testLib.mkCheckScript {
      name = "impermanence";
      assertionResults = assertions;
    }
  )
