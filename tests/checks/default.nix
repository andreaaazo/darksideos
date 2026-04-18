# Checks entrypoint.
# Exposes static analysis checks used by local and CI pipelines.
{
  pkgs,
  self,
}:
import ./checks.nix {
  inherit
    pkgs
    self
    ;
}
