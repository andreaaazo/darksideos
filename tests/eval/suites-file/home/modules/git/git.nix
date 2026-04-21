# Eval tests for standalone shared-modules/home/modules/git/default.nix.
{
  pkgs,
  testLib,
}: let
  fixtureModule = {
    nixpkgs.config.allowUnfree = true;
    users.users.andrea = {
      isNormalUser = true;
      home = "/home/andrea";
    };
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.andrea.home = {
        username = "andrea";
        homeDirectory = "/home/andrea";
        stateVersion = "25.11";
      };
    };
  };

  mkConfig = extraModule:
    testLib.getConfig {
      extraModules = [testLib.hmModule];
      modules = [
        ../../../../../../shared-modules/home/modules/git
        fixtureModule
        extraModule
      ];
    };

  config = mkConfig {};
  secretConfig = mkConfig {
    sops = {
      defaultSopsFile = ../../../../../vm/fixtures/sops/core-secrets.yaml;
      validateSopsFiles = false;
    };
  };

  gitPath = [
    "home-manager"
    "users"
    "andrea"
    "programs"
    "git"
  ];

  assertions = [
    (testLib.assertEnabled {
      id = "home-git-001";
      name = "Git program module is enabled";
      inherit config;
      path = gitPath ++ ["enable"];
      severity = "high";
      rationale = "Git should be managed declaratively instead of installed as an opaque home package";
    })

    (testLib.assertString {
      id = "home-git-002";
      name = "Git user name is explicit";
      inherit config;
      path = gitPath ++ ["settings" "user" "name"];
      expected = "Andrea";
      severity = "high";
      rationale = "Commit identity should be stable across hosts and shells";
    })

    (testLib.assertString {
      id = "home-git-003";
      name = "Git user email is explicit";
      inherit config;
      path = gitPath ++ ["settings" "user" "email"];
      expected = "zorzi.andrea@outlook.com";
      severity = "high";
      rationale = "Commit email should not depend on mutable host-local git config";
    })

    (testLib.assertEnabled {
      id = "home-git-004";
      name = "Git signs commits by default";
      inherit config;
      path = gitPath ++ ["settings" "commit" "gpgSign"];
      severity = "high";
      rationale = "Repository policy requires signed commits";
    })

    (testLib.assertString {
      id = "home-git-005";
      name = "Git uses SSH signing format";
      inherit config;
      path = gitPath ++ ["settings" "gpg" "format"];
      expected = "ssh";
      severity = "high";
      rationale = "SSH signing matches the repository contribution policy";
    })

    (testLib.assertString {
      id = "home-git-006";
      name = "Git default branch is main";
      inherit config;
      path = gitPath ++ ["settings" "init" "defaultBranch"];
      expected = "main";
      severity = "medium";
      rationale = "New repositories should start with the same branch name used by project workflow";
    })

    (testLib.assertEnabled {
      id = "home-git-007";
      name = "Git pull rebases by default";
      inherit config;
      path = gitPath ++ ["settings" "pull" "rebase"];
      severity = "medium";
      rationale = "Linear local history reduces merge noise in trunk-based workflows";
    })

    (testLib.assertString {
      id = "home-git-008";
      name = "Git merge conflict style is zdiff3";
      inherit config;
      path = gitPath ++ ["settings" "merge" "conflictStyle"];
      expected = "zdiff3";
      severity = "medium";
      rationale = "Conflict resolution should preserve base context for reviewable merges";
    })

    (testLib.mkResult {
      id = "home-git-009";
      name = "Git signing key uses standard sops path";
      passed =
        (pkgs.lib.attrByPath
          (gitPath ++ ["settings" "user" "signingKey"])
          null
          config)
        == "/run/secrets/andrea-git-ssh-key";
      expected = "/run/secrets/andrea-git-ssh-key";
      actual =
        pkgs.lib.attrByPath
        (gitPath ++ ["settings" "user" "signingKey"])
        null
        config;
      severity = "high";
      rationale = "Shared Git policy should use one standardized per-host encrypted SSH key";
    })

    (testLib.assertEnabled {
      id = "home-git-010";
      name = "SSH client is managed for Git";
      inherit config;
      path = ["home-manager" "users" "andrea" "programs" "ssh" "enable"];
      severity = "high";
      rationale = "GitHub transport identity should be generated declaratively with the Git module";
    })

    (testLib.assertContains {
      id = "home-git-011";
      name = "GitHub SSH identity uses standard sops path";
      inherit config;
      path = ["home-manager" "users" "andrea" "programs" "ssh" "matchBlocks" "github.com" "data" "identityFile"];
      element = "/run/secrets/andrea-git-ssh-key";
      severity = "high";
      rationale = "Shared SSH policy should reuse the same standardized per-host encrypted SSH key";
    })

    (testLib.assertString {
      id = "home-git-012";
      name = "Git SSH secret is owned by andrea";
      config = secretConfig;
      path = ["sops" "secrets" "andrea-git-ssh-key" "owner"];
      expected = "andrea";
      severity = "high";
      rationale = "Git SSH key must be readable by the user Git process, not exposed globally";
    })

    (testLib.assertString {
      id = "home-git-013";
      name = "Git SSH secret is user-only readable";
      config = secretConfig;
      path = ["sops" "secrets" "andrea-git-ssh-key" "mode"];
      expected = "0400";
      severity = "high";
      rationale = "Git SSH private key should never be group/world readable";
    })
  ];
in
  pkgs.runCommand "eval-home-modules-git" {} (
    testLib.mkCheckScript {
      name = "home/modules/git";
      assertionResults = assertions;
    }
  )
