# Eval tests for shared-modules/home/modules/spotify/default.nix via home/home.nix entrypoint.
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
      id = "home-spotify-001";
      name = "Spotify package is in andrea profile";
      passed =
        builtins.any
        (drv: pkgs.lib.hasInfix "spotify" (toString drv))
        (pkgs.lib.attrByPath [
            "home-manager"
            "users"
            "andrea"
            "home"
            "packages"
          ] []
          config);
      expected = "home.packages containing spotify";
      actual = builtins.map toString (pkgs.lib.attrByPath [
          "home-manager"
          "users"
          "andrea"
          "home"
          "packages"
        ] []
        config);
      severity = "high";
      rationale = "Standalone spotify module should materialize spotify binary in user profile";
    })

    (testLib.mkResult {
      id = "home-spotify-002";
      name = "Spotify Wayland keybind is present";
      passed =
        builtins.any
        (bind: pkgs.lib.hasInfix "spotify --ozone-platform=wayland --enable-features=UseOzonePlatform" bind)
        hyprlandBinds;
      expected = "bind containing spotify with Wayland ozone flags";
      actual = hyprlandBinds;
      severity = "high";
      rationale = "Spotify module should wire deterministic Hyprland launcher binding";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-spotify" {} (
    testLib.mkCheckScript {
      name = "home/modules/spotify";
      assertionResults = assertions;
    }
  )
