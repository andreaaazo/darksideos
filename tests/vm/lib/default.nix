# VM test helper library.
{
  pkgs,
  home-manager,
  impermanence,
  sopsNix,
  zenBrowser,
}: let
  vmTestFactory = import ./mk-vm-test.nix {
    inherit
      pkgs
      home-manager
      impermanence
      sopsNix
      zenBrowser
      ;
  };
in {
  inherit pkgs;

  # Shared Python assertions DSL for VM tests.
  assertions = import ./assertions.nix;

  # VM test factory (host-independent, reusable across suites).
  mkVmTest = vmTestFactory;
}
