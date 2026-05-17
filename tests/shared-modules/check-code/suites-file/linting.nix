# Nix linting check for repository modules.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-shared-modules-linting" {nativeBuildInputs = [pkgs.statix];} ''
  statix check ${self}/shared-modules 2>&1
  touch $out
''
