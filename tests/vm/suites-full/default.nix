# VM suites aggregator for full-stack integration tests.
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
  vm-stack-shared = import ./stack-shared.nix {inherit vmLib;};
}
