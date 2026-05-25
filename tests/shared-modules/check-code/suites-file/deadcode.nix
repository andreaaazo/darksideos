# Nix dead-code check for shared modules.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-shared-modules-deadcode" {nativeBuildInputs = [pkgs.deadnix];} ''
  deadnix --fail ${self}/shared-modules 2>&1
  touch $out
''
