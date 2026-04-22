# VM test for shared-modules/home/modules/features/screenshot/default.nix via home entrypoint.
{vmLib}:
vmLib.mkVmTest {
  name = "home-modules-features-screenshot";
  includeHomeManager = true;
  nodeModules = [
    {
      users.users.andrea = {
        isNormalUser = true;
        home = "/home/andrea";
      };
      system.stateVersion = "25.11";
    }
    ../../../../../../../shared-modules/home
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-home-features-screenshot-001",
        "Screenshot feature binaries are in andrea profile",
        "test -x /etc/profiles/per-user/andrea/bin/grim && test -x /etc/profiles/per-user/andrea/bin/slurp && test -x /etc/profiles/per-user/andrea/bin/wl-copy",
        severity="high",
        rationale="Screenshot feature should materialize grim, slurp, and wl-clipboard binaries",
    )
    assert_command(
        "vm-home-features-screenshot-002",
        "Hyprland config contains screenshot keybind command",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprland.conf; test -f \"$f\" || f=/home/andrea/.config/hypr/hyprland.conf; grep -F \"SHIFT, S, exec\" \"$f\" >/dev/null && grep -F \"/bin/grim -g\" \"$f\" >/dev/null && grep -F \"/bin/slurp\" \"$f\" >/dev/null && grep -F \"/bin/wl-copy\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Screenshot feature keybind should be generated with deterministic store paths",
    )
  '';
}
