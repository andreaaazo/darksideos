# ISO README source inclusion contract.
{testLib}: let
  assertions = [
    (testLib.assertSourceFileExists {
      id = "iso-source-002";
      name = "ISO README is included in flake source";
      relativePath = "iso/README.md";
      severity = "medium";
      rationale = "Release artifacts must be traceable back to local design documentation.";
    })
  ];
in
  testLib.mkEvalTest "eval-iso-source-readme" assertions
