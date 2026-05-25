# ISO hostname eval contract.
{testLib}: let
  config = testLib.installerConfig;

  assertions = [
    (testLib.assertString {
      id = "iso-configuration-003";
      name = "full ISO hostname contract holds";
      inherit config;
      path = [
        "networking"
        "hostName"
      ];
      expected = "darksideos-installer";
      severity = "high";
      rationale = "The full ISO stack must keep the installer identity stable.";
    })
  ];
in
  testLib.mkEvalTest "eval-iso-configuration-hostname" assertions
