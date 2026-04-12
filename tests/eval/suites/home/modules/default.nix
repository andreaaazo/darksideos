# Eval suites for shared-modules/home/modules/*
{
  pkgs,
  testLib,
}: {
  eval-home-modules-features-screenshot = import ./features/screenshot {inherit pkgs testLib;};
  eval-home-modules-google-chrome = import ./google-chrome {inherit pkgs testLib;};
  eval-home-modules-grim = import ./grim {inherit pkgs testLib;};
  eval-home-modules-hyprland = import ./hyprland {inherit pkgs testLib;};
  eval-home-modules-hyprpaper = import ./hyprpaper {inherit pkgs testLib;};
  eval-home-modules-hyprpicker = import ./hyprpicker {inherit pkgs testLib;};
  eval-home-modules-kitty = import ./kitty {inherit pkgs testLib;};
  eval-home-modules-slurp = import ./slurp {inherit pkgs testLib;};
  eval-home-modules-spotify = import ./spotify {inherit pkgs testLib;};
  eval-home-modules-wl-clipboard = import ./wl-clipboard {inherit pkgs testLib;};
}
