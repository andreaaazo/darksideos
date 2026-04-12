# VM test for shared-modules/home/modules/wl-clipboard/default.nix via home/home.nix entrypoint.
{vmLib}:
vmLib.mkVmTest {
  name = "home-modules-wl-clipboard";
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
        "vm-home-wl-clipboard-001",
        "wl-clipboard binaries are in andrea profile",
        "test -x /etc/profiles/per-user/andrea/bin/wl-copy && test -x /etc/profiles/per-user/andrea/bin/wl-paste",
        severity="high",
        rationale="Standalone wl-clipboard module should install clipboard tool binaries in user profile",
    )
  '';
}
