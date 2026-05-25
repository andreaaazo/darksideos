# Checks suites for file-level static analysis.
{
  pkgs,
  self,
}: {
  check-shared-modules-formatting = import ./formatting.nix {inherit pkgs self;};
  check-shared-modules-linting = import ./linting.nix {inherit pkgs self;};
  check-shared-modules-shell = import ./shell.nix {inherit pkgs self;};
  check-shared-modules-deadcode = import ./deadcode.nix {inherit pkgs self;};
  check-shared-modules-syntax = import ./syntax.nix {inherit pkgs self;};
  check-shared-modules-shfmt = import ./shfmt.nix {inherit pkgs self;};
  check-shared-modules-anatomy = import ./anatomy.nix {inherit pkgs self;};
}
