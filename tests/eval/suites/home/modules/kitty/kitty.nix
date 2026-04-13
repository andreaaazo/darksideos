# Eval tests for shared-modules/home/modules/kitty/default.nix via home/home.nix entrypoint.
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
      id = "home-kitty-001";
      name = "Kitty package is in andrea profile";
      passed =
        builtins.any
        (drv: pkgs.lib.hasInfix "kitty" (toString drv))
        (pkgs.lib.attrByPath [
            "home-manager"
            "users"
            "andrea"
            "home"
            "packages"
          ] []
          config);
      expected = "home.packages containing kitty";
      actual = builtins.map toString (pkgs.lib.attrByPath [
          "home-manager"
          "users"
          "andrea"
          "home"
          "packages"
        ] []
        config);
      severity = "high";
      rationale = "Standalone kitty module should materialize terminal binary in user profile";
    })

    (testLib.assertContains {
      id = "home-kitty-002";
      name = "Kitty keybind is present";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "settings"
        "bind"
      ];
      element = "$mainMod, T, exec, ${pkgs.kitty}/bin/kitty";
      severity = "high";
      rationale = "Kitty module should wire deterministic terminal launcher binding";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-kitty" {} (
    testLib.mkCheckScript {
      name = "home/modules/kitty";
      assertionResults = assertions;
    }
  )
