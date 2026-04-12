# Eval suites for shared-modules/graphics/*
{
  pkgs,
  testLib,
}:
(import ./fonts {inherit pkgs testLib;})
// {
  eval-graphics-hyprland = import ./hyprland.nix {inherit pkgs testLib;};
  eval-graphics-portal = import ./portal.nix {inherit pkgs testLib;};
}
