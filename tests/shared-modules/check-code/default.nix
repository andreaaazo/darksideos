# Checks entry point.
# Exposes file-level, module-level, and full-project static checks.
{
  pkgs,
  self,
  system,
}:
import ./suites-file {
  inherit
    pkgs
    self
    ;
}
// import ./suites-module {
  inherit
    pkgs
    self
    ;
}
// import ./suites-full {
  inherit
    pkgs
    self
    ;
}
