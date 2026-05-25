# Shared-modules shell unit tests.
{
  pkgs,
  self,
}: let
  mkUnit = import ./lib/mk-shell-unit.nix {inherit pkgs self;};
in {
  unit-shared-modules-hyprland-window-move = mkUnit "unit-shared-modules-hyprland-window-move" ./home/modules/hyprland/window-move.sh;
  unit-shared-modules-hyprland-window-resize = mkUnit "unit-shared-modules-hyprland-window-resize" ./home/modules/hyprland/window-resize.sh;
}
