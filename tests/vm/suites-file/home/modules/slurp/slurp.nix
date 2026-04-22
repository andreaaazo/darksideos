# VM test for shared-modules/home/modules/slurp/default.nix via home entrypoint.
{vmLib}:
vmLib.mkVmTest {
  name = "home-modules-slurp";
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
        "vm-home-slurp-001",
        "Slurp binary is in andrea profile",
        "test -x /etc/profiles/per-user/andrea/bin/slurp",
        severity="high",
        rationale="Standalone slurp module should install selection helper binary in user profile",
    )
  '';
}
