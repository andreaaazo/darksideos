# VM test for standalone shared-modules/home/modules/git/default.nix.
{vmLib}:
vmLib.mkVmTest {
  name = "home-modules-git";
  includeHomeManager = true;
  nodeModules = [
    {
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
      system.stateVersion = "25.11";
    }
    ../../../../../../shared-modules/home/modules/git
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-home-git-001",
        "Git binary is in andrea profile",
        "test -x /etc/profiles/per-user/andrea/bin/git",
        severity="high",
        rationale="Git module should install the CLI through Home Manager program integration",
    )
    assert_command(
        "vm-home-git-002",
        "Git identity is rendered for andrea",
        "sh -c 'g=$(readlink -f /etc/profiles/per-user/andrea); f=/home/andrea/.config/git/config; test -f \"$f\" || f=\"$g/home-files/.config/git/config\"; test -f \"$f\" && /etc/profiles/per-user/andrea/bin/git config --file \"$f\" --get user.name | grep -Fx \"Andrea\" >/dev/null && /etc/profiles/per-user/andrea/bin/git config --file \"$f\" --get user.email | grep -Fx \"zorzi.andrea@outlook.com\" >/dev/null'",
        severity="high",
        rationale="Runtime git config should not depend on mutable host-local defaults",
    )
    assert_command(
        "vm-home-git-003",
        "Git signing policy is rendered",
        "sh -c 'g=$(readlink -f /etc/profiles/per-user/andrea); f=/home/andrea/.config/git/config; test -f \"$f\" || f=\"$g/home-files/.config/git/config\"; test -f \"$f\" && /etc/profiles/per-user/andrea/bin/git config --file \"$f\" --get gpg.format | grep -Fx \"ssh\" >/dev/null && /etc/profiles/per-user/andrea/bin/git config --file \"$f\" --get commit.gpgsign | grep -Fx \"true\" >/dev/null'",
        severity="high",
        rationale="Runtime git config should enforce repository signed-commit policy",
    )
    assert_command(
        "vm-home-git-004",
        "Git workflow defaults are rendered",
        "sh -c 'g=$(readlink -f /etc/profiles/per-user/andrea); f=/home/andrea/.config/git/config; test -f \"$f\" || f=\"$g/home-files/.config/git/config\"; test -f \"$f\" && /etc/profiles/per-user/andrea/bin/git config --file \"$f\" --get init.defaultBranch | grep -Fx \"main\" >/dev/null && /etc/profiles/per-user/andrea/bin/git config --file \"$f\" --get pull.rebase | grep -Fx \"true\" >/dev/null && /etc/profiles/per-user/andrea/bin/git config --file \"$f\" --get merge.conflictStyle | grep -Fx \"zdiff3\" >/dev/null'",
        severity="medium",
        rationale="Runtime git config should materialize deterministic branch, pull, and merge defaults",
    )
    assert_command(
        "vm-home-git-005",
        "Git signing key uses standard sops path",
        "sh -c 'g=$(readlink -f /etc/profiles/per-user/andrea); f=/home/andrea/.config/git/config; test -f \"$f\" || f=\"$g/home-files/.config/git/config\"; test -f \"$f\" && /etc/profiles/per-user/andrea/bin/git config --file \"$f\" --get user.signingkey | grep -Fx \"/run/secrets/andrea-git-ssh-key\" >/dev/null'",
        severity="high",
        rationale="Runtime Git config should point at the standardized per-host encrypted SSH key",
    )
    assert_command(
        "vm-home-git-006",
        "GitHub SSH identity uses standard sops path",
        "sh -c 'g=$(readlink -f /etc/profiles/per-user/andrea); f=/home/andrea/.ssh/config; test -f \"$f\" || f=\"$g/home-files/.ssh/config\"; test -f \"$f\" && grep -F \"IdentityFile /run/secrets/andrea-git-ssh-key\" \"$f\" >/dev/null && grep -F \"IdentitiesOnly yes\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Runtime SSH config should reuse the standardized per-host encrypted Git SSH key",
    )
  '';
}
