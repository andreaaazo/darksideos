# Eval integration test for shared-modules/impermanence entrypoint.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.impermanenceModule];
    modules = [
      ../../../shared-modules/impermanence
    ];
  };
  persistConfig = config.environment.persistence."/persist";
  assertions = [
    (testLib.assertEnabled {
      id = "module-impermanence-001";
      name = "hideMounts enabled";
      inherit config;
      path = ["environment" "persistence" "/persist" "hideMounts"];
      severity = "medium";
      rationale = "Impermanence integration should hide persistence bind mounts.";
    })
    (testLib.mkResult {
      id = "module-impermanence-002";
      name = "persistence directories count stays minimal";
      passed = builtins.length persistConfig.directories == 5;
      expected = 5;
      actual = builtins.length persistConfig.directories;
      severity = "critical";
      rationale = "Impermanence integration should preserve minimal persisted directory surface.";
    })
    (testLib.mkResult {
      id = "module-impermanence-003";
      name = "persistence files count stays minimal";
      passed = builtins.length persistConfig.files == 2;
      expected = 2;
      actual = builtins.length persistConfig.files;
      severity = "critical";
      rationale = "Impermanence integration should preserve minimal persisted file surface.";
    })
  ];
in
  pkgs.runCommand "eval-module-impermanence" {} (
    testLib.mkCheckScript {
      name = "module/impermanence";
      assertionResults = assertions;
    }
  )
