# Eval tests for shared-modules/home/modules/features/screenshot/default.nix via home/home.nix entrypoint.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.hmModule];
    modules = [
      ../../../../../../../shared-modules/home/home.nix
      {
        nixpkgs.config.allowUnfree = true;
        users.users.andrea = {
          isNormalUser = true;
          home = "/home/andrea";
        };
      }
    ];
  };

  andreaPackages =
    pkgs.lib.attrByPath [
      "home-manager"
      "users"
      "andrea"
      "home"
      "packages"
    ] []
    config;

  assertions = [
    (testLib.assertContains {
      id = "home-features-screenshot-001";
      name = "Screenshot keybind is present";
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
      element = "$mainMod SHIFT, S, exec, ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs."wl-clipboard"}/bin/wl-copy";
      severity = "high";
      rationale = "Screenshot feature module must expose deterministic capture binding";
    })

    (testLib.mkResult {
      id = "home-features-screenshot-002";
      name = "Screenshot feature brings required packages";
      passed =
        builtins.any (drv: pkgs.lib.hasInfix "grim" (toString drv)) andreaPackages
        && builtins.any (drv: pkgs.lib.hasInfix "slurp" (toString drv)) andreaPackages
        && builtins.any (drv: pkgs.lib.hasInfix "wl-clipboard" (toString drv)) andreaPackages;
      expected = "home.packages containing grim, slurp, and wl-clipboard";
      actual = builtins.map toString andreaPackages;
      severity = "high";
      rationale = "Screenshot feature imports grim/slurp/wl-clipboard modules and should materialize their binaries";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-features-screenshot" {} (
    testLib.mkCheckScript {
      name = "home/modules/features/screenshot";
      assertionResults = assertions;
    }
  )
