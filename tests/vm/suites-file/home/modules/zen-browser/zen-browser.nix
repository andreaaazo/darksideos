# VM test for shared-modules/home/modules/zen-browser/default.nix via home entrypoint.
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
    ../../../../../../shared-modules/home
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-home-zen-browser-001",
        "Zen Browser twilight desktop entry is present in andrea profile",
        "test -f /etc/profiles/per-user/andrea/share/applications/zen-twilight.desktop",
        severity="high",
        rationale="Zen Browser module should materialize its desktop integration files in the user profile",
    )
    assert_command(
        "vm-home-zen-browser-002",
        "Home Manager exports Zen browser session variable",
        "grep -E '^export BROWSER=\"?zen[^\"[:space:]]*\"?$' /etc/profiles/per-user/andrea/etc/profile.d/hm-session-vars.sh >/dev/null",
        severity="high",
        rationale="Zen Browser module should expose a Zen-prefixed BROWSER session variable in Home Manager env exports",
    )
    assert_command(
        "vm-home-zen-browser-003",
        "Zen Browser desktop entry is exported in user applications path",
        "test -f /etc/profiles/per-user/andrea/share/applications/zen-twilight.desktop",
        severity="high",
        rationale="Home profile should expose a Zen desktop entry consumable by desktop MIME/default-browser tools",
    )
    assert_command(
        "vm-home-zen-browser-004",
        "Hyprland config file exists for browser bind injection",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprland.conf; test -f \"$f\" || test -f /home/andrea/.config/hypr/hyprland.conf'",
        severity="high",
        rationale="Zen module extends Hyprland settings, so Hyprland config must be materialized in the user environment",
    )
  '';
}
