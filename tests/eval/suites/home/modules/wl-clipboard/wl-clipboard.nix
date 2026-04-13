# Eval tests for shared-modules/home/modules/wl-clipboard/default.nix via home/home.nix entrypoint.
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
      id = "home-wl-clipboard-001";
      name = "wl-clipboard package is in andrea profile";
      passed =
        builtins.any
        (drv: pkgs.lib.hasInfix "wl-clipboard" (toString drv))
        (pkgs.lib.attrByPath [
            "home-manager"
            "users"
            "andrea"
            "home"
            "packages"
          ] []
          config);
      expected = "home.packages containing wl-clipboard";
      actual = builtins.map toString (pkgs.lib.attrByPath [
          "home-manager"
          "users"
          "andrea"
          "home"
          "packages"
        ] []
        config);
      severity = "high";
      rationale = "Standalone wl-clipboard module should provide wl-copy/wl-paste tooling";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-wl-clipboard" {} (
    testLib.mkCheckScript {
      name = "home/modules/wl-clipboard";
      assertionResults = assertions;
    }
  )
