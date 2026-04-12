# Eval suites for shared-modules/graphics/fonts/*
{pkgs, testLib}: {
  eval-graphics-fonts = import ./fonts.nix {inherit pkgs testLib;};
}
