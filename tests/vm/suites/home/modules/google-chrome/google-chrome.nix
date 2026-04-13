# VM test for shared-modules/home/modules/google-chrome/default.nix via home/home.nix entrypoint.
{vmLib}:
vmLib.mkVmTest {
  name = "home-modules-google-chrome";
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
        "vm-home-google-chrome-001",
        "Google Chrome binary is in andrea profile",
        "test -x /etc/profiles/per-user/andrea/bin/google-chrome-stable",
        severity="high",
        rationale="Google Chrome standalone module should install browser binary in user profile",
    )
    assert_command(
        "vm-home-google-chrome-002",
        "Hyprland config contains Google Chrome Wayland launcher bind",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprland.conf; test -f \"$f\" || f=/home/andrea/.config/hypr/hyprland.conf; grep -F \"/bin/google-chrome-stable --ozone-platform=wayland --enable-features=UseOzonePlatform\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Google Chrome launcher bind should use deterministic Wayland flags and store path",
    )
  '';
}
