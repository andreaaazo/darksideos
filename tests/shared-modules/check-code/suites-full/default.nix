# Checks suites for full project integration surfaces.
{
  pkgs,
  self,
}: {
  check-stack-shared-modules = import ./project.nix {
    inherit
      pkgs
      self
      ;
  };
}
