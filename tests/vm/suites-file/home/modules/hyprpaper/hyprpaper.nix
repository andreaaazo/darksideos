# VM test for shared-modules/home/modules/hyprpaper/default.nix via home entrypoint.
{vmLib}:
vmLib.mkVmTest {
  name = "home-modules-hyprpaper";
  includeHomeManager = true;
  nodeModules = [
    {
      users.users.andrea = {
        isNormalUser = true;
        home = "/home/andrea";
      };
      system.stateVersion = "25.11";
    }
    ../../../../../../shared-modules/home
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-home-hyprpaper-001",
        "Hyprpaper binary is in andrea profile",
        "test -x /etc/profiles/per-user/andrea/bin/hyprpaper",
        severity="high",
        rationale="Standalone hyprpaper module should install wallpaper daemon binary in user profile",
    )
    assert_command(
        "vm-home-hyprpaper-002",
        "Hyprpaper config is materialized with wallpaper policy",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprpaper.conf; test -f \"$f\" || f=/home/andrea/.config/hypr/hyprpaper.conf; test -f \"$f\" && grep -E \"^[[:space:]]*path[[:space:]]*=.*wallpaper\\.jpg$\" \"$f\" >/dev/null && grep -E \"^[[:space:]]*fit_mode[[:space:]]*=[[:space:]]*cover$\" \"$f\" >/dev/null && grep -E \"^[[:space:]]*splash[[:space:]]*=[[:space:]]*false$\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Hyprpaper module should materialize explicit wallpaper path, fit mode, and splash policy",
    )
    assert_command(
        "vm-home-hyprpaper-003",
        "Hyprpaper user systemd unit is generated",
        "sh -c 'u=/etc/profiles/per-user/andrea/share/systemd/user/hyprpaper.service; test -f \"$u\" || u=/home/andrea/.config/systemd/user/hyprpaper.service; test -f \"$u\" && grep -F \"/bin/hyprpaper\" \"$u\" >/dev/null'",
        severity="high",
        rationale="Hyprpaper startup should remain managed by generated user systemd unit",
    )
  '';
}
