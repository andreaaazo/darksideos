# Eval tests for shared-modules/home/modules/vim/default.nix via home entrypoint.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.hmModule];
    modules = [
      ../../../../../../shared-modules/home
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
      id = "home-vim-001";
      name = "Vim package is in andrea profile";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "home"
        "packages"
      ];
      substring = "vim";
      severity = "medium";
      rationale = "Shared Home baseline should keep a minimal terminal editor available";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-vim" {} (
    testLib.mkCheckScript {
      name = "home/modules/vim";
      assertionResults = assertions;
    }
  )
