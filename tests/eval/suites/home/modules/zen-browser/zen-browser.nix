# Eval tests for shared-modules/home/modules/zen-browser/default.nix via home/home.nix entrypoint.
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
      id = "home-zen-browser-001";
      name = "Zen Browser package is in andrea profile";
      passed =
        builtins.any
        (drv: pkgs.lib.hasInfix "zen-browser" (toString drv))
        (pkgs.lib.attrByPath [
            "home-manager"
            "users"
            "andrea"
            "home"
            "packages"
          ] []
          config);
      expected = "home.packages containing zen-browser";
      actual = builtins.map toString (pkgs.lib.attrByPath [
          "home-manager"
          "users"
          "andrea"
          "home"
          "packages"
        ] []
        config);
      severity = "high";
      rationale = "Standalone Zen Browser module should materialize browser package in user profile";
    })

    (testLib.mkResult {
      id = "home-zen-browser-002";
      name = "Zen Browser Wayland keybind is present";
      passed =
        builtins.any
        (bind:
          pkgs.lib.hasInfix "zen-browser" bind
          && pkgs.lib.hasInfix "--ozone-platform=wayland --enable-features=UseOzonePlatform" bind)
        hyprlandBinds;
      expected = "bind containing zen-browser launcher with Wayland ozone flags";
      actual = hyprlandBinds;
      severity = "high";
      rationale = "Zen Browser module should wire deterministic Hyprland launcher binding";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-zen-browser" {} (
    testLib.mkCheckScript {
      name = "home/modules/zen-browser";
      assertionResults = assertions;
    }
  )
