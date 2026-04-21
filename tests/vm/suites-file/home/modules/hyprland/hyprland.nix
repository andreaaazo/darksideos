# VM test for shared-modules/home/modules/hyprland/default.nix via home/home.nix entrypoint.
{vmLib}:
vmLib.mkVmTest {
  name = "home-modules-hyprland";
  includeHomeManager = true;
  nodeModules = [
    {
      users.users.andrea = {
        isNormalUser = true;
        home = "/home/andrea";
      };
      system.stateVersion = "25.11";
    }
    ../../../../../../shared-modules/home/home.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-home-hyprland-001",
        "Hyprland config file is materialized for andrea",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprland.conf; test -f \"$f\" || f=/home/andrea/.config/hypr/hyprland.conf; test -f \"$f\"'",
        severity="high",
        rationale="Hyprland user configuration must be present from declarative Home Manager source",
    )
    assert_command(
        "vm-home-hyprland-002",
        "Hyprland config includes core window-management bindings",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprland.conf; test -f \"$f\" || f=/home/andrea/.config/hypr/hyprland.conf; grep -F \"killactive\" \"$f\" >/dev/null && grep -F \"togglefloating\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Generated Hyprland config should include minimal core window-management key actions",
    )
    assert_command(
        "vm-home-hyprland-003",
        "Home Manager session exports user-level cursor sizes",
        "test -f /etc/profiles/per-user/andrea/etc/profile.d/hm-session-vars.sh && grep -E '^export XCURSOR_SIZE=\"24\"$' /etc/profiles/per-user/andrea/etc/profile.d/hm-session-vars.sh >/dev/null && grep -E '^export HYPRCURSOR_SIZE=\"24\"$' /etc/profiles/per-user/andrea/etc/profile.d/hm-session-vars.sh >/dev/null",
        severity="medium",
        rationale="Cursor size policy must remain user-scoped and materialized by Home Manager",
    )
    assert_command(
        "vm-home-hyprland-004",
        "system profile exposes desktop and portal link paths",
        "test -d /run/current-system/sw/share/applications && test -d /run/current-system/sw/share/xdg-desktop-portal",
        severity="high",
        rationale="pathsToLink policy must expose desktop entries and portal definitions at system profile level",
    )
    assert_command(
        "vm-home-hyprland-005",
        "Hyprland config injects cursor size env for session startup",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprland.conf; test -f \"$f\" || f=/home/andrea/.config/hypr/hyprland.conf; grep -E \"^[[:space:]]*env[[:space:]]*=[[:space:]]*XCURSOR_SIZE,24([[:space:]]|$)\" \"$f\" >/dev/null && grep -E \"^[[:space:]]*env[[:space:]]*=[[:space:]]*HYPRCURSOR_SIZE,24([[:space:]]|$)\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Hyprland should receive cursor size from user config even without shell profile sourcing",
    )
    assert_command(
        "vm-home-hyprland-006",
        "Hyprpaper config is materialized with requested monitor/path/fit/splash policy",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprpaper.conf; test -f \"$f\" || f=/home/andrea/.config/hypr/hyprpaper.conf; test -f \"$f\" && grep -E \"^[[:space:]]*monitor[[:space:]]*=[[:space:]]*$\" \"$f\" >/dev/null && grep -E \"^[[:space:]]*path[[:space:]]*=.*wallpaper\\.jpg$\" \"$f\" >/dev/null && grep -E \"^[[:space:]]*fit_mode[[:space:]]*=[[:space:]]*cover$\" \"$f\" >/dev/null && grep -E \"^[[:space:]]*splash[[:space:]]*=[[:space:]]*false$\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Hyprpaper configuration must stay declarative and explicit for all monitors",
    )
    assert_command(
        "vm-home-hyprland-007",
        "Hyprpaper user unit is generated and tied to graphical session target",
        "sh -c 'u=/etc/profiles/per-user/andrea/share/systemd/user/hyprpaper.service; test -f \"$u\" || u=/home/andrea/.config/systemd/user/hyprpaper.service; test -f \"$u\" && grep -F \"ExecStart=\" \"$u\" >/dev/null && grep -F \"/bin/hyprpaper\" \"$u\" >/dev/null && grep -F \"WantedBy=graphical-session.target\" \"$u\" >/dev/null'",
        severity="high",
        rationale="Hyprpaper startup should be managed by systemd user units, not hyprland exec-once",
    )
    assert_command(
        "vm-home-hyprland-008",
        "Hyprpaper referenced wallpaper asset exists in immutable store",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprpaper.conf; test -f \"$f\" || f=/home/andrea/.config/hypr/hyprpaper.conf; p=$(sed -nE \"s/^[[:space:]]*path[[:space:]]*=[[:space:]]*(.*)$/\\1/p\" \"$f\" | head -n1); test -n \"$p\" && test -e \"$p\" && printf \"%s\" \"$p\" | grep -E \"wallpaper\\.jpg$\" >/dev/null'",
        severity="medium",
        rationale="Hyprpaper wallpaper path should resolve to a real immutable asset",
    )
    assert_command(
        "vm-home-hyprland-009",
        "Hyprpaper binary is available in user profile bin",
        "test -x /etc/profiles/per-user/andrea/bin/hyprpaper",
        severity="high",
        rationale="Standalone hyprpaper module should install binary into user profile",
    )
    assert_command(
        "vm-home-hyprland-010",
        "Hyprland config uses current windowrule syntax",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprland.conf; test -f \"$f\" || f=/home/andrea/.config/hypr/hyprland.conf; grep -E \"^[[:space:]]*windowrule[[:space:]]*=[[:space:]]*opacity 0[.]80 override 0[.]80 override, match:class [\\^][(]spotify[)][$]\" \"$f\" >/dev/null && grep -E \"^[[:space:]]*windowrule[[:space:]]*=[[:space:]]*no_shadow on, match:fullscreen true\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Generated Hyprland config must use current windowrule/match syntax",
    )
    assert_command(
        "vm-home-hyprland-011",
        "Hyprland config does not emit legacy windowrulev2",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprland.conf; test -f \"$f\" || f=/home/andrea/.config/hypr/hyprland.conf; ! grep -F \"windowrulev2\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Deprecated windowrulev2 should not be present in runtime config",
    )
  '';
}
