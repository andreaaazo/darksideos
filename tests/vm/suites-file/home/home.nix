# VM test for shared-modules/home/home.nix
{vmLib}:
vmLib.mkVmTest {
  name = "home-home";
  includeHomeManager = true;
  nodeModules = [
    {
      # VM fixture: define user referenced by shared Home Manager policy.
      users.users.andrea = {
        isNormalUser = true;
        home = "/home/andrea";
      };
      system.stateVersion = "25.11";
    }
    ../../../../shared-modules/home/home.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-home-001",
        "andrea user exists with expected home directory",
        "getent passwd andrea | awk -F: '{print $1\":\"$6}' | grep -x 'andrea:/home/andrea'",
        severity="high",
        rationale="Home Manager policy is bound to the andrea account and expected home path",
    )
    assert_command(
        "vm-home-002",
        "home-manager service unit for andrea is installed",
        "systemctl cat home-manager-andrea.service >/dev/null",
        severity="high",
        rationale="NixOS Home Manager integration must materialize per-user activation service",
    )
    assert_command(
        "vm-home-003",
        "home-manager service is loaded",
        "systemctl show -p LoadState --value home-manager-andrea.service | grep -x 'loaded'",
        severity="high",
        rationale="Systemd should load the generated Home Manager unit correctly",
    )
    assert_command(
        "vm-home-004",
        "home-manager service has an ExecStart command",
        "systemctl show -p ExecStart --value home-manager-andrea.service | grep -q .",
        severity="high",
        rationale="Generated Home Manager unit must define an activation command",
    )
    assert_command(
        "vm-home-005",
        "per-user profile path for andrea exists in /etc/profiles",
        "test -L /etc/profiles/per-user/andrea",
        severity="high",
        rationale="useUserPackages policy should materialize per-user profile under /etc/profiles",
    )
    assert_command(
        "vm-home-006",
        "per-user profile symlink resolves into nix store",
        "readlink -f /etc/profiles/per-user/andrea | grep -E '^/nix/store/' >/dev/null",
        severity="high",
        rationale="Per-user profile target should be immutable store path",
    )
    assert_command(
        "vm-home-007",
        "home-manager session variables script exists in per-user profile",
        "test -f /etc/profiles/per-user/andrea/etc/profile.d/hm-session-vars.sh",
        severity="medium",
        rationale="Home Manager generation should include standard session environment script",
    )
    assert_command(
        "vm-home-008",
        "Home Manager reference manpages are absent from andrea profile",
        "! find /etc/profiles/per-user/andrea/share/man -type f \\( -name 'home-manager.1*' -o -name 'home-configuration.nix.5*' \\) 2>/dev/null | grep -q .",
        severity="medium",
        rationale="manual.manpages.enable=false should skip Home Manager-specific manpage generation",
    )
    assert_command(
        "vm-home-009",
        "no failed units after home-manager integration",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="Home Manager shared policy must not introduce boot-time service failures",
    )
  '';
}
