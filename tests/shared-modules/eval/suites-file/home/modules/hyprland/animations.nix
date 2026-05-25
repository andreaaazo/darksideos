# Eval tests for shared-modules/home/modules/hyprland/animations.nix.
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

  animationsPath = [
    "home-manager"
    "users"
    "andrea"
    "wayland"
    "windowManager"
    "hyprland"
    "settings"
    "animations"
    "animation"
  ];

  assertions = [
    (testLib.assertContains {
      id = "home-hyprland-animations-workspaces";
      name = "Workspace switch animation is slidevert";
      inherit config;
      path = animationsPath;
      element = "workspaces, 1, 6, default, slidevert";
      severity = "medium";
      rationale = "Workspace transitions must remain consistent with the declared animation contract.";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-hyprland-animations" {} (
    testLib.mkCheckScript {
      name = "home/modules/hyprland/animations";
      assertionResults = assertions;
    }
  )
