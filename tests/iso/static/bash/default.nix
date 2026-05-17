{
  pkgs,
  self,
  mkAggregate,
}: let
  tests = {
    check-iso-bash-formatting = import ./formatting.nix {inherit pkgs self;};
    check-iso-bash-syntax = import ./syntax.nix {inherit pkgs self;};
    check-iso-shellcheck = import ./shellcheck.nix {inherit pkgs self;};
    check-iso-script-anatomy = import ./anatomy.nix {inherit pkgs self;};
    check-iso-script-imports = import ./imports.nix {inherit pkgs self;};
    check-iso-bash-reachability = import ./reachability.nix {inherit pkgs self;};
    check-iso-legacy-paths = import ./legacy-paths.nix {inherit pkgs self;};
  };
in
  tests
  // {
    iso-check-static-bash = mkAggregate {
      inherit pkgs;
      name = "iso-check-static-bash";
      tests = builtins.attrValues tests;
    };
  }
