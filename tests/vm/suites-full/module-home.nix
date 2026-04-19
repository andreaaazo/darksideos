# VM integration test for shared-modules/home (full module entrypoint).
{vmLib}:
vmLib.mkVmTest {
  name = "module-home";
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
    ../../../shared-modules/home
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-module-home-001",
        "home-manager service unit for andrea is installed",
        "systemctl cat home-manager-andrea.service >/dev/null",
        severity="high",
        rationale="Home integration entrypoint must materialize per-user HM activation unit",
    )
    assert_command(
        "vm-module-home-002",
        "system profile exposes desktop entries link path",
        "test -d /run/current-system/sw/share/applications",
        severity="high",
        rationale="Home module should preserve pathsToLink policy for desktop entries",
    )
    assert_command(
        "vm-module-home-003",
        "system profile exposes portal definition link path",
        "test -d /run/current-system/sw/share/xdg-desktop-portal",
        severity="high",
        rationale="Home module should preserve pathsToLink policy for portal definitions",
    )
    assert_command(
        "vm-module-home-004",
        "andrea per-user profile exists",
        "test -L /etc/profiles/per-user/andrea",
        severity="high",
        rationale="Home integration should keep useUserPackages profile materialization",
    )
    assert_command(
        "vm-module-home-005",
        "no failed units after integrated home activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="Home integrated module should not introduce boot-time failures",
    )
  '';
}
