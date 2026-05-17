# Factory for host-independent headless NixOS VM tests.
{
  pkgs,
  home-manager,
  impermanence,
  sopsNix,
  zenBrowser,
}: let
  # External NixOS modules consumed by VM test nodes.
  externalModules = {
    # Home Manager module (flake output attr uses hyphen in source namespace).
    homeManager = home-manager.nixosModules.home-manager;
    inherit (impermanence.nixosModules) impermanence;
    inherit (sopsNix.nixosModules) sops;
  };

  # Build deterministic base module args for each VM node.
  # NOTE: zenBrowser is a flake input value, so it is propagated through
  # specialArgs/_module.args; sops is a NixOS module, so it is imported.
  mkBaseModule = {
    hostName,
    stateVersion,
  }:
    import ./base-module.nix {
      inherit
        hostName
        stateVersion
        zenBrowser
        ;
    };
in
  {
    name,
    includeHomeManager ? false,
    includeImpermanence ? false,
    nodeModules ? [],
    hostName ? "vm-test-host",
    stateVersion ? "25.11",
    testScript ? "",
  }: let
    baseModule = mkBaseModule {
      inherit
        hostName
        stateVersion
        ;
    };
  in
    pkgs.testers.runNixOSTest {
      name = "vm-${name}";

      # Provide flake input args for all nodes (required by modules that reference specialArgs in imports/config).
      node.specialArgs = {inherit zenBrowser;};

      nodes.machine = {...}: {
        imports =
          [
            baseModule
            externalModules.sops
          ]
          ++ pkgs.lib.optionals includeHomeManager [externalModules.homeManager]
          ++ pkgs.lib.optionals includeImpermanence [externalModules.impermanence]
          ++ nodeModules;
      };

      testScript = ''
        start_all()
        machine.wait_for_unit("multi-user.target")

        ${testScript}
      '';
    }
