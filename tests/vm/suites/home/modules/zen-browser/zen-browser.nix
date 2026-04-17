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
        "Zen Browser twilight package is present in andrea profile closure",
        "nix-store -q --references /etc/profiles/per-user/andrea | grep -F 'zen-twilight' >/dev/null",
        severity="high",
        rationale="Zen Browser flake module should materialize twilight package in user profile closure",
    )
    assert_command(
        "vm-home-zen-browser-002",
        "Home Manager exports Zen twilight as default browser in session vars",
        "grep -F 'BROWSER=zen-twilight' /etc/profiles/per-user/andrea/etc/profile.d/hm-session-vars.sh >/dev/null",
        severity="high",
        rationale="Zen Browser module should set BROWSER session variable when default browser mode is enabled",
    )
    assert_command(
        "vm-home-zen-browser-003",
        "MIME apps map HTTP handler to Zen twilight desktop entry",
        "grep -F 'x-scheme-handler/http=zen-twilight.desktop' /etc/profiles/per-user/andrea/etc/xdg/mimeapps.list >/dev/null",
        severity="high",
        rationale="Default browser integration must register Zen twilight as HTTP handler",
    )
    assert_command(
        "vm-home-zen-browser-004",
        "Hyprland config contains Zen Browser Wayland launcher bind",
        "sh -c 'f=/etc/profiles/per-user/andrea/etc/xdg/hypr/hyprland.conf; test -f \"$f\" || f=/home/andrea/.config/hypr/hyprland.conf; grep -F \"--ozone-platform=wayland --enable-features=UseOzonePlatform\" \"$f\" >/dev/null && grep -F \"zen-\" \"$f\" >/dev/null'",
        severity="high",
        rationale="Zen Browser launcher bind should use deterministic executable path and explicit Wayland flags",
    )
  '';
}
