# VM test helper library.
{
  pkgs,
  home-manager,
  impermanence,
  sopsNix,
  zenBrowser,
}: {
  inherit pkgs;
  # Base module injects common _module.args used by shared module tests.
  baseModule = import ./base-module.nix {inherit zenBrowser;};
  assertions = import ./assertions.nix;
  mkVmTest = import ./mk-vm-test.nix {
    inherit
      pkgs
      home-manager
      impermanence
      sopsNix
      zenBrowser
      ;
  };
}
