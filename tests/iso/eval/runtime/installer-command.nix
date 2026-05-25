# Installer command runtime contract.
{testLib}: let
  assertions = [
    (testLib.assertPackagePresent {
      id = "iso-runtime-001";
      name = "darksideos-install command is shipped";
      packageName = "darksideos-install";
      severity = "critical";
      rationale = "The ISO is not useful unless the installer entrypoint is available on PATH.";
    })
  ];
in
  testLib.mkEvalTest "eval-iso-runtime-installer-command" assertions
