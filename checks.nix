# Flake checks: formatting, linting, and dead code detection.
# Each check fails the build if issues are found.
{
  pkgs,
  self,
}: {
  formatting = pkgs.runCommand "check-formatting" {nativeBuildInputs = [pkgs.alejandra];} ''
    alejandra --check ${self} 2>&1
    touch $out
  '';

  linting = pkgs.runCommand "check-linting" {nativeBuildInputs = [pkgs.statix];} ''
    statix check ${self} 2>&1
    touch $out
  '';

  deadcode = pkgs.runCommand "check-deadcode" {nativeBuildInputs = [pkgs.deadnix];} ''
    deadnix --fail ${self} 2>&1
    touch $out
  '';
}
