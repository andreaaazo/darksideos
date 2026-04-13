# Eval tests for shared-modules/home/modules/google-chrome/default.nix via home/home.nix entrypoint.
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

  hyprlandBinds =
    pkgs.lib.attrByPath [
      "home-manager"
      "users"
      "andrea"
      "wayland"
      "windowManager"
      "hyprland"
      "settings"
      "bind"
    ] []
    config;

  assertions = [
    (testLib.mkResult {
      id = "home-google-chrome-001";
      name = "Google Chrome package is in andrea profile";
      passed =
        builtins.any
        (drv: pkgs.lib.hasInfix "google-chrome" (toString drv))
        (pkgs.lib.attrByPath [
            "home-manager"
            "users"
            "andrea"
            "home"
            "packages"
          ] []
          config);
      expected = "home.packages containing google-chrome";
      actual = builtins.map toString (pkgs.lib.attrByPath [
          "home-manager"
          "users"
          "andrea"
          "home"
          "packages"
        ] []
        config);
      severity = "high";
      rationale = "Standalone Google Chrome module should materialize browser package in user profile";
    })

    (testLib.mkResult {
      id = "home-google-chrome-002";
      name = "Google Chrome Wayland keybind is present";
      passed =
        builtins.any
        (bind: pkgs.lib.hasInfix "google-chrome-stable --ozone-platform=wayland --enable-features=UseOzonePlatform" bind)
        hyprlandBinds;
      expected = "bind containing google-chrome-stable with Wayland ozone flags";
      actual = hyprlandBinds;
      severity = "high";
      rationale = "Google Chrome module should wire deterministic Hyprland launcher binding";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-google-chrome" {} (
    testLib.mkCheckScript {
      name = "home/modules/google-chrome";
      assertionResults = assertions;
    }
  )
