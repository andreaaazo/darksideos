# VM test for shared-modules/home/modules/vim/default.nix via home entrypoint.
{vmLib}:
vmLib.mkVmTest {
  name = "home-modules-vim";
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
        "vm-home-vim-001",
        "Vim binary is in andrea profile",
        "test -x /etc/profiles/per-user/andrea/bin/vim",
        severity="medium",
        rationale="Shared Home baseline should install a minimal terminal editor in the user profile",
    )
  '';
}
