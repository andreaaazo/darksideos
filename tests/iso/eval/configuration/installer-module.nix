# Eval tests for the composed installer ISO module.
{testLib}: let
  config = testLib.installerConfig;

  assertions = [
    (testLib.assertString {
      id = "iso-configuration-004";
      name = "minimal installer variant is active";
      inherit config;
      path = [
        "system"
        "nixos"
        "variant_id"
      ];
      expected = "installer";
      severity = "critical";
      rationale = "The flake must import a NixOS installer ISO module, not a normal host profile.";
    })

    (testLib.assertEnabled {
      id = "iso-configuration-005";
      name = "ISO is EFI bootable";
      inherit config;
      path = [
        "isoImage"
        "makeEfiBootable"
      ];
      severity = "critical";
      rationale = "Modern test and install machines must be able to boot the ISO through UEFI.";
    })

    (testLib.assertEnabled {
      id = "iso-configuration-006";
      name = "ISO is USB bootable";
      inherit config;
      path = [
        "isoImage"
        "makeUsbBootable"
      ];
      severity = "critical";
      rationale = "The installer ISO must remain usable from physical USB media.";
    })

    (testLib.assertSourceContains {
      id = "iso-configuration-007";
      name = "flake imports the minimal NixOS installer module";
      source = testLib.flakeSource;
      substring = "installation-cd-minimal.nix";
      severity = "critical";
      rationale = "The custom ISO must remain based on the minimal installer module.";
    })
  ];
in
  testLib.mkEvalTest "eval-iso-configuration-installer-module" assertions
