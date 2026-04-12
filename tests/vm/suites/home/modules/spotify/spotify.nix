# VM test for shared-modules/home/modules/spotify/default.nix via home/home.nix entrypoint.
{vmLib}:
vmLib.mkVmTest {
  name = "home-modules-spotify";
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
        "vm-home-spotify-001",
        "Spotify binary is in andrea profile",
        "test -x /etc/profiles/per-user/andrea/bin/spotify",
        severity="high",
        rationale="Standalone spotify module should install Spotify binary in user profile",
    )
    assert_command(
        "vm-home-spotify-002",
        "Hyprland config contains Spotify Wayland launcher bind",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprland.conf; test -f \"$f\" || f=/home/andrea/.config/hypr/hyprland.conf; grep -F \"/bin/spotify --ozone-platform=wayland --enable-features=UseOzonePlatform\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Spotify launcher bind should be generated with deterministic Wayland flags and store path",
    )
  '';
}
