# Eval tests for shared-modules/home/modules/slurp/default.nix via home/home.nix entrypoint.
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
      id = "home-slurp-001";
      name = "Slurp package is in andrea profile";
      passed =
        builtins.any
        (drv: pkgs.lib.hasInfix "slurp" (toString drv))
        (pkgs.lib.attrByPath [
            "home-manager"
            "users"
            "andrea"
            "home"
            "packages"
          ] []
          config);
      expected = "home.packages containing slurp";
      actual = builtins.map toString (pkgs.lib.attrByPath [
          "home-manager"
          "users"
          "andrea"
          "home"
          "packages"
        ] []
        config);
      severity = "high";
      rationale = "Standalone slurp module should materialize slurp binary in user profile";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-slurp" {} (
    testLib.mkCheckScript {
      name = "home/modules/slurp";
      assertionResults = assertions;
    }
  )
