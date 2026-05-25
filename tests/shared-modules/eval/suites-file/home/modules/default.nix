# Eval suites for shared-modules/home/modules/*
{
  pkgs,
  testLib,
}: {
  eval-home-modules-features-screenshot = import ./features/screenshot {inherit pkgs testLib;};
  eval-home-modules-grim = import ./grim {inherit pkgs testLib;};
  eval-home-modules-hyprland = import ./hyprland {inherit pkgs testLib;};
  eval-home-modules-hyprland-bindings = import ./hyprland/bindings.nix {inherit pkgs testLib;};
  eval-home-modules-hyprland-theme = import ./hyprland/theme.nix {inherit pkgs testLib;};
  eval-home-modules-hyprland-animations = import ./hyprland/animations.nix {inherit pkgs testLib;};
  eval-home-modules-hyprland-input = import ./hyprland/input.nix {inherit pkgs testLib;};
  eval-home-modules-hyprland-rules = import ./hyprland/rules.nix {inherit pkgs testLib;};
  eval-home-modules-hyprland-system = import ./hyprland/system.nix {inherit pkgs testLib;};
  eval-home-modules-hyprpaper = import ./hyprpaper {inherit pkgs testLib;};
  eval-home-modules-hyprpicker = import ./hyprpicker {inherit pkgs testLib;};
  eval-home-modules-kitty = import ./kitty {inherit pkgs testLib;};
  eval-home-modules-slurp = import ./slurp {inherit pkgs testLib;};
  eval-home-modules-spotify = import ./spotify {inherit pkgs testLib;};
  eval-home-modules-wl-clipboard = import ./wl-clipboard {inherit pkgs testLib;};
  eval-home-modules-zen-browser = import ./zen-browser {inherit pkgs testLib;};
}
