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

  defaultHttpApp =
    pkgs.lib.attrByPath [
      "home-manager"
      "users"
      "andrea"
      "xdg"
      "mimeApps"
      "defaultApplications"
      "x-scheme-handler/http"
    ]
    null
    config;

  assertions = [
    (testLib.mkResult {
      id = "home-zen-browser-001";
      name = "Zen Browser module is enabled";
      passed = pkgs.lib.attrByPath ["home-manager" "users" "andrea" "programs" "zen-browser" "enable"] false config;
      expected = "programs.zen-browser.enable = true";
      actual = pkgs.lib.attrByPath ["home-manager" "users" "andrea" "programs" "zen-browser" "enable"] null config;
      severity = "high";
      rationale = "Zen Browser feature must be enabled via flake-provided Home Manager module";
    })

    (testLib.mkResult {
      id = "home-zen-browser-002";
      name = "Zen Browser is configured as default browser";
      passed = pkgs.lib.attrByPath ["home-manager" "users" "andrea" "programs" "zen-browser" "setAsDefaultBrowser"] false config;
      expected = "programs.zen-browser.setAsDefaultBrowser = true";
      actual = pkgs.lib.attrByPath ["home-manager" "users" "andrea" "programs" "zen-browser" "setAsDefaultBrowser"] null config;
      severity = "high";
      rationale = "Zen Browser should own URL and web MIME associations declaratively";
    })

    (testLib.mkResult {
      id = "home-zen-browser-003";
      name = "HTTP default application is Zen twilight desktop entry";
      passed =
        defaultHttpApp
        == "zen-twilight.desktop"
        || (builtins.isList defaultHttpApp && defaultHttpApp == ["zen-twilight.desktop"]);
      expected = "xdg.mimeApps.defaultApplications.x-scheme-handler/http = zen-twilight.desktop";
      actual = defaultHttpApp;
      severity = "high";
      rationale = "Default browser integration should map HTTP handler to Zen twilight desktop entry";
    })

    (testLib.mkResult {
      id = "home-zen-browser-004";
      name = "BROWSER session variable is set to Zen twilight launcher";
      passed = pkgs.lib.attrByPath ["home-manager" "users" "andrea" "home" "sessionVariables" "BROWSER"] "" config == "zen-twilight";
      expected = "home.sessionVariables.BROWSER = zen-twilight";
      actual = pkgs.lib.attrByPath ["home-manager" "users" "andrea" "home" "sessionVariables" "BROWSER"] null config;
      severity = "high";
      rationale = "CLI/browser-aware tools should resolve Zen as default browser from session environment";
    })

    (testLib.assertAnyContainsAllStringified {
      id = "home-zen-browser-005";
      name = "Zen Browser Wayland keybind is present";
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
      substrings = [
        "exec, /nix/store/"
        "--ozone-platform=wayland --enable-features=UseOzonePlatform"
      ];
      severity = "high";
      rationale = "Zen Browser launcher should be deterministic and force native Wayland execution";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-zen-browser" {} (
    testLib.mkCheckScript {
      name = "home/modules/zen-browser";
      assertionResults = assertions;
    }
  )
