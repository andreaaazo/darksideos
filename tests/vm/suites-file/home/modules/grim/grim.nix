# VM test for shared-modules/home/modules/grim/default.nix via home entrypoint.
{vmLib}:
vmLib.mkVmTest {
  name = "home-modules-grim";
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
        "vm-home-grim-001",
        "Grim binary is in andrea profile",
        "test -x /etc/profiles/per-user/andrea/bin/grim",
        severity="high",
        rationale="Standalone grim module should install screenshot binary in user profile",
    )
  '';
}
