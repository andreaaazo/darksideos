# Formatting check for repository Nix files.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-shared-modules-formatting" {nativeBuildInputs = [pkgs.alejandra];} ''
  alejandra --check ${self}/shared-modules 2>&1
  touch $out
''
