# Eval suites for shared-modules/home/modules/*
{
  pkgs,
  testLib,
}: {
  eval-home-modules-features-screenshot = import ./features/screenshot {inherit pkgs testLib;};
  eval-home-modules-git = import ./git {inherit pkgs testLib;};
  eval-home-modules-grim = import ./grim {inherit pkgs testLib;};
  eval-home-modules-hyprland = import ./hyprland {inherit pkgs testLib;};
  eval-home-modules-hyprpaper = import ./hyprpaper {inherit pkgs testLib;};
  eval-home-modules-hyprpicker = import ./hyprpicker {inherit pkgs testLib;};
  eval-home-modules-kitty = import ./kitty {inherit pkgs testLib;};
  eval-home-modules-slurp = import ./slurp {inherit pkgs testLib;};
  eval-home-modules-spotify = import ./spotify {inherit pkgs testLib;};
  eval-home-modules-vim = import ./vim {inherit pkgs testLib;};
  eval-home-modules-wl-clipboard = import ./wl-clipboard {inherit pkgs testLib;};
  eval-home-modules-zen-browser = import ./zen-browser {inherit pkgs testLib;};
}
