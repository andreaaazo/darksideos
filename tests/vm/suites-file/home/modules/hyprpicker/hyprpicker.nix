# VM test for shared-modules/home/modules/hyprpicker/default.nix via home entrypoint.
{vmLib}:
vmLib.mkVmTest {
  name = "home-modules-hyprpicker";
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
        "vm-home-hyprpicker-001",
        "Hyprpicker binary is in andrea profile",
        "test -x /etc/profiles/per-user/andrea/bin/hyprpicker",
        severity="high",
        rationale="Standalone hyprpicker module should install color picker binary in user profile",
    )
    assert_command(
        "vm-home-hyprpicker-002",
        "Hyprland config contains hyprpicker launcher bind",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprland.conf; test -f \"$f\" || f=/home/andrea/.config/hypr/hyprland.conf; grep -F \"/bin/hyprpicker -a\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Hyprpicker launcher bind should be generated with deterministic store path",
    )
  '';
}
