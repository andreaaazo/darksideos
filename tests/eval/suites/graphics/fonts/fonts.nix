# Eval tests for shared-modules/graphics/fonts/fonts.nix
# Verifies font stack and fontconfig defaults.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    modules = [
      ../../../../../shared-modules/graphics/fonts/fonts.nix
    ];
  };

  assertions = [
    (testLib.assertDisabled {
      id = "fonts-001";
      name = "Default font packages disabled";
      inherit config;
      path = [
        "fonts"
        "enableDefaultPackages"
      ];
      severity = "high";
      rationale = "Only explicitly declared fonts should exist on system";
    })

    (testLib.assertContains {
      id = "fonts-002";
      name = "Monospace default is JetBrains Nerd Font";
      inherit config;
      path = [
        "fonts"
        "fontconfig"
        "defaultFonts"
        "monospace"
      ];
      element = "JetBrainsMono Nerd Font";
      severity = "high";
      rationale = "Terminal and code editors need consistent monospace font";
    })

    (testLib.assertContains {
      id = "fonts-003";
      name = "Sans-serif default is Inter";
      inherit config;
      path = [
        "fonts"
        "fontconfig"
        "defaultFonts"
        "sansSerif"
      ];
      element = "Inter";
      severity = "high";
      rationale = "UI and body text need consistent sans-serif font";
    })

    (testLib.assertContains {
      id = "fonts-004";
      name = "Serif fallback is Inter";
      inherit config;
      path = [
        "fonts"
        "fontconfig"
        "defaultFonts"
        "serif"
      ];
      element = "Inter";
      severity = "medium";
      rationale = "No dedicated serif font, Inter used as fallback";
    })

    (testLib.assertContains {
      id = "fonts-005";
      name = "Emoji default is Apple Color Emoji";
      inherit config;
      path = [
        "fonts"
        "fontconfig"
        "defaultFonts"
        "emoji"
      ];
      element = "Apple Color Emoji";
      severity = "high";
      rationale = "Consistent emoji rendering across all apps";
    })

    (testLib.assertDisabled {
      id = "fonts-006";
      name = "bitmap fonts are disabled";
      inherit config;
      path = [
        "fonts"
        "fontconfig"
        "allowBitmaps"
      ];
      severity = "high";
      rationale = "Rejecting bitmap fonts avoids legacy fallback rendering";
    })

    (testLib.assertDisabled {
      id = "fonts-007";
      name = "user fontconfig overrides are disabled";
      inherit config;
      path = [
        "fonts"
        "fontconfig"
        "includeUserConf"
      ];
      severity = "high";
      rationale = "Shared baseline should not be bypassed by per-user fontconfig files";
    })
  ];
in
  pkgs.runCommand "eval-graphics-fonts" {} (
    testLib.mkCheckScript {
      name = "graphics/fonts";
      assertionResults = assertions;
    }
  )
