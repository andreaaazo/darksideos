# Eval suites for shared-modules/home/modules/*
{
  pkgs,
  testLib,
}: {
  eval-home-modules-hyprland = import ./hyprland {inherit pkgs testLib;};
}
