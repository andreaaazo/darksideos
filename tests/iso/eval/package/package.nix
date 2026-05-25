# Eval tests for packages.x86_64-linux.darksideos-installer-iso.
{testLib}: let
  isoPackage = testLib.installerIsoPackage;
  configIsoPackage = testLib.installerConfig.system.build.isoImage;

  assertions = [
    (testLib.assertTrue {
      id = "iso-package-001";
      name = "darksideos-installer-iso package evaluates";
      actual = (isoPackage.type or null) == "derivation";
      severity = "critical";
      rationale = "The flake package entry point must be evaluable before CI attempts an ISO build.";
    })

    (testLib.assertTrue {
      id = "iso-package-002";
      name = "package entry point uses the installer NixOS ISO image";
      actual = builtins.toString isoPackage == builtins.toString configIsoPackage;
      severity = "critical";
      rationale = "The flake package must not drift away from nixosConfigurations.darksideos-installer.";
    })
  ];
in
  testLib.mkEvalTest "eval-iso-package" assertions
