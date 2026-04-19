# VM suites for shared-modules/graphics/fonts/*
{vmLib}: {
  vm-graphics-fonts = import ./fonts.nix {inherit vmLib;};
}
