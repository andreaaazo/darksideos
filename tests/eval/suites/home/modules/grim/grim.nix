# Eval tests for shared-modules/home/modules/grim/default.nix via home/home.nix entrypoint.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.hmModule];
    modules = [
      ../../../../../../shared-modules/home/home.nix
      {
        nixpkgs.config.allowUnfree = true;
        users.users.andrea = {
          isNormalUser = true;
          home = "/home/andrea";
        };
      }
    ];
  };

  assertions = [
    (testLib.mkResult {
      id = "home-grim-001";
      name = "Grim package is in andrea profile";
      passed =
        builtins.any
        (drv: pkgs.lib.hasInfix "grim" (toString drv))
        (pkgs.lib.attrByPath [
            "home-manager"
            "users"
            "andrea"
            "home"
            "packages"
          ] []
          config);
      expected = "home.packages containing grim";
      actual = builtins.map toString (pkgs.lib.attrByPath [
          "home-manager"
          "users"
          "andrea"
          "home"
          "packages"
        ] []
        config);
      severity = "high";
      rationale = "Standalone grim module should materialize grim binary in user profile";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-grim" {} (
    testLib.mkCheckScript {
      name = "home/modules/grim";
      assertionResults = assertions;
    }
  )
