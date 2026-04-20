# Eval tests for shared-modules/home/modules/hyprland/default.nix via home/home.nix entrypoint.
# Verifies user-level Hyprland Home Manager policy.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.hmModule];
    modules = [
      ../../../../../../shared-modules/home/home.nix
      # Stub: define user so home-manager can resolve homeDirectory.
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

  hyprpaperPlaceholderPath = ../../../../../../shared-modules/home/modules/hyprpaper/wallpaper/wallpaper.jpg;

  assertions = [
    (testLib.assertEnabled {
      id = "home-hyprland-001";
      name = "Home Manager Hyprland module enabled for andrea";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "enable"
      ];
      severity = "high";
      rationale = "Hyprland user configuration must be declared through Home Manager options";
    })

    (testLib.assertEqual {
      id = "home-hyprland-002";
      name = "XCURSOR_SIZE is set at user level";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "home"
        "sessionVariables"
        "XCURSOR_SIZE"
      ];
      expected = "24";
      severity = "medium";
      rationale = "Cursor size should be user-scoped for per-profile tuning";
    })

    (testLib.assertEqual {
      id = "home-hyprland-003";
      name = "HYPRCURSOR_SIZE is set at user level";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "home"
        "sessionVariables"
        "HYPRCURSOR_SIZE"
      ];
      expected = "24";
      severity = "medium";
      rationale = "Hyprland cursor size should be user-scoped for reproducible per-user behavior";
    })

    (testLib.assertContains {
      id = "home-hyprland-004";
      name = "Hyprland env exports XCURSOR_SIZE";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "settings"
        "env"
      ];
      element = "XCURSOR_SIZE,24";
      severity = "high";
      rationale = "Hyprland session should receive explicit user-level X cursor size";
    })

    (testLib.assertContains {
      id = "home-hyprland-005";
      name = "Hyprland env exports HYPRCURSOR_SIZE";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "settings"
        "env"
      ];
      element = "HYPRCURSOR_SIZE,24";
      severity = "high";
      rationale = "Hyprland session should receive explicit user-level Hypr cursor size";
    })

    (testLib.assertContains {
      id = "home-hyprland-006";
      name = "pathsToLink includes desktop entry linking";
      inherit config;
      path = [
        "environment"
        "pathsToLink"
      ];
      element = "/share/applications";
      severity = "high";
      rationale = "Home Manager user packages must expose desktop entries system-wide";
    })

    (testLib.assertContains {
      id = "home-hyprland-007";
      name = "pathsToLink includes xdg portal linking";
      inherit config;
      path = [
        "environment"
        "pathsToLink"
      ];
      element = "/share/xdg-desktop-portal";
      severity = "medium";
      rationale = "Home Manager Hyprland profile needs portal definition linking when useUserPackages is enabled";
    })

    (testLib.assertContains {
      id = "home-hyprland-008";
      name = "Hyprpaper user service ExecStart is pinned to nix store binary";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "systemd"
        "user"
        "services"
        "hyprpaper"
        "Service"
        "ExecStart"
      ];
      element = "${pkgs.hyprpaper}/bin/hyprpaper";
      severity = "high";
      rationale = "Hyprpaper startup must be fully declarative and reproducible";
    })

    (testLib.assertAnyHasSuffixStringified {
      id = "home-hyprland-009";
      name = "Hyprpaper service is wired to a user session target";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "systemd"
        "user"
        "services"
        "hyprpaper"
        "Install"
        "WantedBy"
      ];
      suffix = "session.target";
      severity = "medium";
      rationale = "Wallpaper daemon must be started by systemd user session target";
    })

    (testLib.assertStringContains {
      id = "home-hyprland-010";
      name = "Hyprpaper config disables splash";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "xdg"
        "configFile"
        "hypr/hyprpaper.conf"
        "text"
      ];
      substring = "splash=false";
      severity = "medium";
      rationale = "Requested Hyprpaper policy requires splash screen disabled";
    })

    (testLib.mkResult {
      id = "home-hyprland-011";
      name = "Hyprpaper config applies wallpaper to all monitors with cover mode";
      passed =
        pkgs.lib.hasInfix "monitor=" hyprpaperConf
        && pkgs.lib.hasInfix "fit_mode=cover" hyprpaperConf
        && pkgs.lib.hasInfix "wallpaper.jpg" hyprpaperConf;
      expected = "hyprpaper.conf containing monitor=, fit_mode=cover, and wallpaper.jpg path";
      actual = hyprpaperConf;
      severity = "high";
      rationale = "Wallpaper policy should target all monitors with explicit cover fit mode";
    })

    (testLib.assertEnabled {
      id = "home-hyprland-012";
      name = "Official Home Manager hyprpaper module is enabled";
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
      rationale = "Hyprpaper should be configured via official Home Manager module options";
    })

    (testLib.mkResult {
      id = "home-hyprland-013";
      name = "Placeholder wallpaper source file exists in repository";
      passed = builtins.pathExists hyprpaperPlaceholderPath;
      expected = true;
      actual = builtins.pathExists hyprpaperPlaceholderPath;
      severity = "high";
      rationale = "Wallpaper asset placeholder must be materialized declaratively";
    })

    (testLib.assertAnyContainsStringified {
      id = "home-hyprland-014";
      name = "Hyprpaper binary is included in user package profile";
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
      rationale = "Standalone app module should expose hyprpaper binary in user profile";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-hyprland" {} (
    testLib.mkCheckScript {
      name = "home/modules/hyprland";
      assertionResults = assertions;
    }
  )
