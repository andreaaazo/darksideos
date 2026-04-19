# VM suites aggregator for full-stack integration tests.
{
  pkgs,
  home-manager,
  impermanence,
}: let
  vmLib = import ../lib {
    inherit
      pkgs
      home-manager
      impermanence
      ;
  };
in {
  vm-stack-shared = import ./stack-shared.nix {inherit vmLib;};
}
