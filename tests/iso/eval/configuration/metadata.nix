# Eval tests for ISO naming metadata.
{testLib}: let
  config = testLib.installerConfig;

  assertions = [
    (testLib.assertString {
      id = "iso-metadata-001";
      name = "ISO file name is stable";
      inherit config;
      path = [
        "image"
        "fileName"
      ];
      expected = "darksideos-installer.iso";
      severity = "critical";
      rationale = "CI and manual installation flows need a predictable ISO artifact name.";
    })

    (testLib.assertString {
      id = "iso-metadata-002";
      name = "ISO volume ID is stable";
      inherit config;
      path = [
        "isoImage"
        "volumeID"
      ];
      expected = "DARKSIDEOS";
      severity = "high";
      rationale = "The live medium should be clearly identifiable during installation.";
    })
  ];
in
  testLib.mkEvalTest "eval-iso-metadata" assertions
