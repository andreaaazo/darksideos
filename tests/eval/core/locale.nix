# Eval tests for shared-modules/core/locale.nix
# Verifies locale, timezone, and keyboard configuration.
{
  pkgs,
  testLib,
}: let
  # Evaluate only the locale module in isolation
  config = testLib.getConfig {
    modules = [
      ../../../shared-modules/core/locale.nix
    ];
  };

  # Define assertions for this module
  assertions = [
    (testLib.assertString {
      id = "locale-001";
      name = "timezone set to Europe/Zurich";
      inherit config;
      path = [
        "time"
        "timeZone"
      ];
      expected = "Europe/Zurich";
      severity = "medium";
      rationale = "Ensures correct CET/CEST time with DST switching";
    })

    (testLib.assertString {
      id = "locale-002";
      name = "default locale is en_US.UTF-8";
      inherit config;
      path = [
        "i18n"
        "defaultLocale"
      ];
      expected = "en_US.UTF-8";
      severity = "medium";
      rationale = "System language set to English";
    })

    (testLib.assertString {
      id = "locale-003";
      name = "LC_TIME uses Swiss-German format";
      inherit config;
      path = [
        "i18n"
        "extraLocaleSettings"
        "LC_TIME"
      ];
      expected = "de_CH.UTF-8";
      severity = "low";
      rationale = "Date/time formatting follows Swiss conventions";
    })

    (testLib.assertString {
      id = "locale-004";
      name = "console keymap is Swiss German";
      inherit config;
      path = [
        "console"
        "keyMap"
      ];
      expected = "sg";
      severity = "medium";
      rationale = "TTY keyboard layout for Swiss German";
    })

    (testLib.assertString {
      id = "locale-005";
      name = "X11/Wayland keyboard layout is ch";
      inherit config;
      path = [
        "services"
        "xserver"
        "xkb"
        "layout"
      ];
      expected = "ch";
      severity = "medium";
      rationale = "Graphical sessions use Swiss keyboard layout";
    })

    (testLib.assertString {
      id = "locale-006";
      name = "X11/Wayland keyboard variant is de";
      inherit config;
      path = [
        "services"
        "xserver"
        "xkb"
        "variant"
      ];
      expected = "de";
      severity = "medium";
      rationale = "Swiss-German variant for graphical sessions";
    })
  ];
in
  pkgs.runCommand "eval-core-locale" {} (
    testLib.mkCheckScript {
      name = "core/locale";
      assertionResults = assertions;
    }
  )
