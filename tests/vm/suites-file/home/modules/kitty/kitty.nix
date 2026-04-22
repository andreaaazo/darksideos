# VM test for shared-modules/home/modules/kitty/default.nix via home entrypoint.
{vmLib}:
vmLib.mkVmTest {
  name = "home-modules-kitty";
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
        "vm-home-kitty-001",
        "Kitty binary is in andrea profile",
        "test -x /etc/profiles/per-user/andrea/bin/kitty",
        severity="high",
        rationale="Standalone kitty module should install terminal binary in user profile",
    )
    assert_command(
        "vm-home-kitty-002",
        "Hyprland config contains kitty launcher bind",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprland.conf; test -f \"$f\" || f=/home/andrea/.config/hypr/hyprland.conf; grep -F \"/bin/kitty\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Kitty launcher bind should be generated with deterministic store path",
    )
  '';
}
