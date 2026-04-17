# Factory for host-independent headless NixOS VM tests.
{
  pkgs,
  home-manager,
  impermanence,
  zenBrowser,
}: {
  name,
  includeHomeManager ? false,
  includeImpermanence ? false,
  nodeModules ? [],
  hostName ? "vm-test-host",
  stateVersion ? "25.11",
  testScript ? "",
}: let
  baseModule = import ./base-module.nix {
    inherit
      hostName
      stateVersion
      zenBrowser
      ;
  };
in
  pkgs.testers.runNixOSTest {
    name = "vm-${name}";

    # Provide external module arguments for all nodes (required for modules that use args in `imports`).
    node.specialArgs = {inherit zenBrowser;};

    nodes.machine = {...}: {
      imports =
        [baseModule]
        ++ pkgs.lib.optionals includeHomeManager [home-manager.nixosModules.home-manager]
        ++ pkgs.lib.optionals includeImpermanence [impermanence.nixosModules.impermanence]
        ++ nodeModules;
    };

    testScript = ''
      start_all()
      machine.wait_for_unit("multi-user.target")

      ${testScript}
    '';
  }
