# VM integration test for shared-modules/graphics (full module entrypoint).
{vmLib}:
vmLib.mkVmTest {
  name = "module-graphics";
  nodeModules = [
    ../../../shared-modules/graphics
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-module-graphics-001",
        "Hyprland package is available in system profile",
        "command -v Hyprland >/dev/null",
        severity="high",
        rationale="Graphics entrypoint should install compositor binary",
    )
    assert_command(
        "vm-module-graphics-002",
        "portal broker user service unit is installed",
        "test -f /run/current-system/sw/share/systemd/user/xdg-desktop-portal.service",
        severity="high",
        rationale="Graphics integration must expose portal broker service",
    )
    assert_command(
        "vm-module-graphics-003",
        "Hyprland portal user service unit is installed",
        "test -f /run/current-system/sw/share/systemd/user/xdg-desktop-portal-hyprland.service",
        severity="high",
        rationale="Graphics integration must expose Hyprland backend service",
    )
    assert_command(
        "vm-module-graphics-004",
        "portal routing config file exists",
        "test -f /etc/xdg/xdg-desktop-portal/portals.conf",
        severity="high",
        rationale="Graphics integration must materialize deterministic portal routing",
    )
    assert_command(
        "vm-module-graphics-005",
        "no failed units after integrated graphics activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="Graphics integrated module should not introduce runtime failures",
    )
  '';
}
