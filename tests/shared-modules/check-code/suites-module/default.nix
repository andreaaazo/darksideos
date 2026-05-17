# Checks suites for module-level project surfaces.
{
  pkgs,
  self,
}: {
  check-module-shared-modules-nixos-configurations = import ./nixos-configurations.nix {inherit pkgs self;};
}
