# VM suites for shared-modules/graphics/*
{vmLib}:
(import ./fonts {inherit vmLib;})
// {
  vm-graphics-audio = import ./audio.nix {inherit vmLib;};
  vm-graphics-hyprland = import ./hyprland.nix {inherit vmLib;};
  vm-graphics-portal = import ./portal.nix {inherit vmLib;};
}
