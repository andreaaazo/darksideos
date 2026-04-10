# VM test helper library.
{
  pkgs,
  home-manager,
  impermanence,
}: {
  inherit pkgs;
  baseModule = import ./base-module.nix {};
  assertions = import ./assertions.nix;
  mkVmTest = import ./mk-vm-test.nix {
    inherit
      pkgs
      home-manager
      impermanence
      ;
  };
}
