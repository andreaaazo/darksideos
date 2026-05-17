# Eval tests for nixosConfigurations.darksideos-installer.
{testLib}: let
  config = testLib.installerConfig;

  assertions = [
    (testLib.assertTrue {
      id = "iso-configuration-001";
      name = "darksideos-installer NixOS configuration evaluates";
      actual = (testLib.installerConfiguration.config.system.build.toplevel.type or null) == "derivation";
      severity = "critical";
      rationale = "The installer ISO must remain a valid NixOS configuration before any boot test can run.";
    })

    (testLib.assertString {
      id = "iso-configuration-002";
      name = "installer hostname is explicit";
      inherit config;
      path = [
        "networking"
        "hostName"
      ];
      expected = "darksideos-installer";
      severity = "critical";
      rationale = "The live ISO hostname is part of the observable installer identity.";
    })
  ];
in
  testLib.mkEvalTest "eval-iso-configuration" assertions
