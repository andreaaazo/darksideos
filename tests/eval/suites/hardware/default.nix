# Eval suites for shared-modules/hardware/*
{
  pkgs,
  testLib,
}: {
  eval-hardware-audio = import ./audio.nix {inherit pkgs testLib;};
  eval-hardware-bluetooth = import ./bluetooth.nix {inherit pkgs testLib;};
  eval-hardware-cpu-intel = import ./cpu-intel.nix {inherit pkgs testLib;};
  eval-hardware-gpu-nvidia = import ./gpu-nvidia.nix {inherit pkgs testLib;};
}
