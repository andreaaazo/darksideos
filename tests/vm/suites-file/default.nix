# VM suites aggregator for file-level and module-slice tests.
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
in
  (import ./core {inherit vmLib;})
  // (import ./graphics {inherit vmLib;})
  // (import ./home {inherit vmLib;})
  // (import ./hardware {inherit vmLib;})
  // (import ./impermanence {inherit vmLib;})
