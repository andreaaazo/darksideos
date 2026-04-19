# VM suites aggregator for module-integration tests.
{
  pkgs,
  home-manager,
  impermanence,
  zenBrowser,
}: let
  vmLib = import ../lib {
    inherit
      pkgs
      home-manager
      impermanence
      zenBrowser
      ;
  };
in {
  vm-module-core = import ./module-core.nix {inherit vmLib;};
  vm-module-graphics = import ./module-graphics.nix {inherit vmLib;};
  vm-module-hardware = import ./module-hardware.nix {inherit vmLib;};
  vm-module-home = import ./module-home.nix {inherit vmLib;};
  vm-module-impermanence = import ./module-impermanence.nix {inherit vmLib;};
}
