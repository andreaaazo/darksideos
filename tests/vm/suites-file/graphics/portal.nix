# VM test for shared-modules/graphics/portal.nix
{vmLib}:
vmLib.mkVmTest {
  name = "graphics-portal";
  nodeModules = [
    ../../../../shared-modules/graphics/portal.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-portal-001",
        "system D-Bus socket exists",
        "test -S /run/dbus/system_bus_socket",
        severity="critical",
        rationale="Portal stack depends on the system D-Bus bus",
    )
    assert_command(
        "vm-portal-002",
        "D-Bus is reachable via busctl",
        "busctl --system list >/dev/null",
        severity="critical",
        rationale="Runtime bus reachability is required for portal activation and requests",
    )
    assert_command(
        "vm-portal-003",
        "xdg-desktop-portal broker service unit is installed",
        "test -f /run/current-system/sw/share/systemd/user/xdg-desktop-portal.service",
        severity="high",
        rationale="Core portal broker user service must exist",
    )
    assert_command(
        "vm-portal-004",
        "xdg-desktop-portal-gtk service unit is installed",
        "test -f /run/current-system/sw/share/systemd/user/xdg-desktop-portal-gtk.service",
        severity="high",
        rationale="GTK portal backend user service must exist",
    )
    assert_command(
        "vm-portal-006",
        "GTK portal definition is installed",
        "test -f /run/current-system/sw/share/xdg-desktop-portal/portals/gtk.portal",
        severity="high",
        rationale="GTK backend must advertise implemented portal interfaces",
    )
    assert_command(
        "vm-portal-008",
        "portal broker D-Bus service file is installed",
        "test -f /run/current-system/sw/share/dbus-1/services/org.freedesktop.portal.Desktop.service",
        severity="high",
        rationale="Portal broker must be discoverable by D-Bus activation",
    )
    assert_command(
        "vm-portal-009",
        "GTK portal D-Bus service file is installed",
        "test -f /run/current-system/sw/share/dbus-1/services/org.freedesktop.impl.portal.desktop.gtk.service",
        severity="high",
        rationale="GTK backend must be discoverable by D-Bus service activation",
    )
    assert_command(
        "vm-portal-011",
        "portal directory session variable is exported",
        "grep -E '^export NIX_XDG_DESKTOP_PORTAL_DIR=\"/run/current-system/sw/share/xdg-desktop-portal/portals\"$' /etc/set-environment >/dev/null",
        severity="high",
        rationale="Applications must know where portal definitions are exposed",
    )
    assert_command(
        "vm-portal-012",
        "xdg-open is configured to use portal",
        "grep -E '^export NIXOS_XDG_OPEN_USE_PORTAL=\"1\"$' /etc/set-environment >/dev/null",
        severity="high",
        rationale="Portal mode for xdg-open must be explicitly exported in runtime environment",
    )
    assert_command(
        "vm-portal-013",
        "portal routing config file exists",
        "test -f /etc/xdg/xdg-desktop-portal/portals.conf",
        severity="high",
        rationale="Explicit backend routing must be materialized in portals.conf",
    )
    assert_command(
        "vm-portal-014",
        "default portal routing is hyprland then gtk",
        "grep -E '^default=hyprland;gtk$' /etc/xdg/xdg-desktop-portal/portals.conf >/dev/null",
        severity="high",
        rationale="Default backend ordering must stay deterministic",
    )
    assert_command(
        "vm-portal-015",
        "ScreenCast routed to hyprland",
        "grep -E '^org\\.freedesktop\\.impl\\.portal\\.ScreenCast=hyprland$' /etc/xdg/xdg-desktop-portal/portals.conf >/dev/null",
        severity="high",
        rationale="Screencast requests must route to Hyprland backend",
    )
    assert_command(
        "vm-portal-016",
        "Screenshot routed to hyprland",
        "grep -E '^org\\.freedesktop\\.impl\\.portal\\.Screenshot=hyprland$' /etc/xdg/xdg-desktop-portal/portals.conf >/dev/null",
        severity="high",
        rationale="Screenshot requests must route to Hyprland backend",
    )
    assert_command(
        "vm-portal-017",
        "RemoteDesktop routed to hyprland",
        "grep -E '^org\\.freedesktop\\.impl\\.portal\\.RemoteDesktop=hyprland$' /etc/xdg/xdg-desktop-portal/portals.conf >/dev/null",
        severity="high",
        rationale="RemoteDesktop requests must route to Hyprland backend",
    )
    assert_command(
        "vm-portal-018",
        "FileChooser routed to gtk",
        "grep -E '^org\\.freedesktop\\.impl\\.portal\\.FileChooser=gtk$' /etc/xdg/xdg-desktop-portal/portals.conf >/dev/null",
        severity="high",
        rationale="FileChooser requests must route to GTK backend",
    )
    assert_command(
        "vm-portal-019",
        "Settings routed to gtk",
        "grep -E '^org\\.freedesktop\\.impl\\.portal\\.Settings=gtk$' /etc/xdg/xdg-desktop-portal/portals.conf >/dev/null",
        severity="high",
        rationale="Settings requests must route to GTK backend",
    )
    assert_command(
        "vm-portal-020",
        "no failed units after portal policy activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="Portal shared policy must not introduce startup failures",
    )
  '';
}
