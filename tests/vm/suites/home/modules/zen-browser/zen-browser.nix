# VM test for shared-modules/home/modules/zen-browser/default.nix via home/home.nix entrypoint.
{vmLib}:
vmLib.mkVmTest {
  name = "home-modules-zen-browser";
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
        "vm-home-zen-browser-001",
        "Zen Browser package is present in andrea profile closure",
        "nix-store -q --references /etc/profiles/per-user/andrea | grep -F 'zen-browser' >/dev/null",
        severity="high",
        rationale="Zen Browser standalone module should install browser package in user profile closure",
    )
    assert_command(
        "vm-home-zen-browser-002",
        "Hyprland config contains Zen Browser Wayland launcher bind",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprland.conf; test -f \"$f\" || f=/home/andrea/.config/hypr/hyprland.conf; grep -F \"zen-browser\" \"$f\" >/dev/null && grep -F \"--ozone-platform=wayland --enable-features=UseOzonePlatform\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Zen Browser launcher bind should use deterministic store path and Wayland ozone flags",
    )
  '';
}
