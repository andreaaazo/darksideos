# Eval tests for ISO documentation and schema files included in the flake source.
{testLib}: let
  requiredSourceFiles = [
    "iso/README.md"
    "iso/schemas/create-new-host-plan.v1.schema.json"
  ];

  assertions =
    builtins.map
    (relativePath:
      testLib.assertSourceFileExists {
        id = "iso-source-${builtins.hashString "sha256" relativePath}";
        name = "flake source includes ${relativePath}";
        inherit relativePath;
        severity = "high";
        rationale = "The installer contract must ship with its local design documentation and IDL schema.";
      })
    requiredSourceFiles;
in
  testLib.mkEvalTest "eval-iso-source-files" assertions
