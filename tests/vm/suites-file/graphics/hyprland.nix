# VM test for shared-modules/graphics/hyprland.nix
{vmLib}:
vmLib.mkVmTest {
  name = "graphics-hyprland";
  nodeModules = [
    ../../../../shared-modules/graphics/hyprland.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-hyprland-001",
        "Hyprland compositor binary is installed",
        "command -v Hyprland >/dev/null",
        severity="critical",
        rationale="Hyprland must be present in the runtime system profile",
    )
    assert_command(
        "vm-hyprland-002",
        "Hyprland portal preference config is installed",
        "test -f /run/current-system/sw/share/xdg-desktop-portal/hyprland-portals.conf",
        severity="high",
        rationale="Hyprland module should provide portal routing config via configPackages",
    )
    assert_command(
        "vm-hyprland-003",
        "XWayland server binary is not installed",
        "! command -v Xwayland >/dev/null",
        severity="high",
        rationale="Shared profile keeps a pure Wayland baseline without XWayland compatibility",
    )
    assert_command(
        "vm-hyprland-004",
        "PolicyKit service unit is available",
        "systemctl cat polkit.service >/dev/null",
        severity="critical",
        rationale="Hyprland workflows depend on polkit authorization service",
    )
    assert_command(
        "vm-hyprland-005",
        "XDG_SESSION_TYPE is exported as wayland",
        "grep -E '^export XDG_SESSION_TYPE=\"wayland\"$' /etc/set-environment >/dev/null",
        severity="high",
        rationale="Runtime environment must advertise Wayland session type",
    )
    assert_command(
        "vm-hyprland-006",
        "XDG_CURRENT_DESKTOP is exported as Hyprland",
        "grep -E '^export XDG_CURRENT_DESKTOP=\"Hyprland\"$' /etc/set-environment >/dev/null",
        severity="high",
        rationale="Runtime environment must advertise Hyprland desktop identity",
    )
    assert_command(
        "vm-hyprland-007",
        "NIXOS_OZONE_WL is exported",
        "grep -E '^export NIXOS_OZONE_WL=\"1\"$' /etc/set-environment >/dev/null",
        severity="high",
        rationale="Chromium/Electron Ozone Wayland toggle must be present in session env",
    )
    assert_command(
        "vm-hyprland-008",
        "MOZ_ENABLE_WAYLAND is exported",
        "grep -E '^export MOZ_ENABLE_WAYLAND=\"1\"$' /etc/set-environment >/dev/null",
        severity="high",
        rationale="Firefox Wayland toggle must be present in session env",
    )
    assert_command(
        "vm-hyprland-009",
        "UWSM binary is installed",
        "command -v uwsm >/dev/null",
        severity="high",
        rationale="withUWSM baseline requires the session manager binary at runtime",
    )
    assert_command(
        "vm-hyprland-010",
        "Hyprland systemd PATH helper config is not injected",
        "! grep -R 'DefaultEnvironment=\"PATH=/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:$PATH\"' /etc/systemd >/dev/null 2>&1",
        severity="medium",
        rationale="systemd.setPath.enable=false should keep this module PATH patch disabled",
    )
    assert_command(
        "vm-hyprland-011",
        "xdg-desktop-portal user service unit is installed",
        "test -f /run/current-system/sw/share/systemd/user/xdg-desktop-portal.service",
        severity="high",
        rationale="Wayland portal broker unit must be available in user session manager",
    )
    assert_command(
        "vm-hyprland-012",
        "Hyprland portal user service unit is installed",
        "test -f /run/current-system/sw/share/systemd/user/xdg-desktop-portal-hyprland.service",
        severity="high",
        rationale="Hyprland portal backend service must be present for portal requests",
    )
    assert_command(
        "vm-hyprland-013",
        "Hyprland portal D-Bus service file is installed",
        "test -f /run/current-system/sw/share/dbus-1/services/org.freedesktop.impl.portal.desktop.hyprland.service",
        severity="high",
        rationale="Portal backend must be discoverable by D-Bus service activation",
    )
    assert_command(
        "vm-hyprland-014",
        "Hyprland portal definition is installed",
        "test -f /run/current-system/sw/share/xdg-desktop-portal/portals/hyprland.portal",
        severity="high",
        rationale="Hyprland portal backend must be registered for screen/file portal flows",
    )
    assert_command(
        "vm-hyprland-015",
        "no failed units after Hyprland policy activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="Hyprland shared policy must not introduce startup failures",
    )
    assert_command(
        "vm-hyprland-016",
        "XCURSOR_THEME is exported as phinger-cursors",
        "grep -E '^export XCURSOR_THEME=\"phinger-cursors\"$' /etc/set-environment >/dev/null",
        severity="high",
        rationale="System cursor theme must be globally exported for deterministic desktop behavior",
    )
    assert_command(
        "vm-hyprland-017",
        "HYPRCURSOR_THEME is exported as phinger-cursors",
        "grep -E '^export HYPRCURSOR_THEME=\"phinger-cursors\"$' /etc/set-environment >/dev/null",
        severity="high",
        rationale="Hyprland cursor theme should align with global cursor policy",
    )
    assert_command(
        "vm-hyprland-018",
        "Phinger cursor package is present in system closure",
        "nix-store -q --references /run/current-system/sw | grep -i 'phinger-cursors' >/dev/null",
        severity="high",
        rationale="Selected cursor package should be retained in immutable system profile closure",
    )
  '';
}
