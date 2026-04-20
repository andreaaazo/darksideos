# Eval tests for shared-modules/home/modules/hyprpaper/default.nix via home/home.nix entrypoint.
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

  hyprpaperConf =
    pkgs.lib.attrByPath [
      "home-manager"
      "users"
      "andrea"
      "xdg"
      "configFile"
      "hypr/hyprpaper.conf"
      "text"
    ] ""
    config;

  assertions = [
    (testLib.assertEnabled {
      id = "home-hyprpaper-001";
      name = "Home Manager hyprpaper service is enabled";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "services"
        "hyprpaper"
        "enable"
      ];
      severity = "high";
      rationale = "Hyprpaper module must configure wallpaper daemon declaratively through Home Manager";
    })

    (testLib.assertAnyContainsStringified {
      id = "home-hyprpaper-002";
      name = "Hyprpaper package is in andrea profile";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "home"
        "packages"
      ];
      substring = "hyprpaper";
      severity = "high";
      rationale = "Standalone hyprpaper module should expose binary in user profile";
    })

    (testLib.mkResult {
      id = "home-hyprpaper-003";
      name = "Hyprpaper config includes wallpaper asset and cover mode";
      passed =
        pkgs.lib.hasInfix "wallpaper.jpg" hyprpaperConf
        && pkgs.lib.hasInfix "fit_mode=cover" hyprpaperConf
        && pkgs.lib.hasInfix "splash=false" hyprpaperConf;
      expected = "hyprpaper.conf containing wallpaper.jpg, fit_mode=cover, and splash=false";
      actual = hyprpaperConf;
      severity = "high";
      rationale = "Wallpaper policy should stay explicit and reproducible";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-hyprpaper" {} (
    testLib.mkCheckScript {
      name = "home/modules/hyprpaper";
      assertionResults = assertions;
    }
  )
