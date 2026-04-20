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

  assertions = [
    (testLib.assertAnyContainsStringified {
      id = "home-spotify-001";
      name = "Spotify package is in andrea profile";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "home"
        "packages"
      ];
      substring = "spotify";
      severity = "high";
      rationale = "Standalone spotify module should materialize spotify binary in user profile";
    })

    (testLib.assertAnyContainsStringified {
      id = "home-spotify-002";
      name = "Spotify Wayland keybind is present";
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
      substring = "spotify --ozone-platform=wayland --enable-features=UseOzonePlatform";
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
