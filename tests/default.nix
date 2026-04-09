# Eval test aggregator.
# Collects all eval tests and exposes them as flake checks.
# Structure mirrors shared-modules/ for discoverability.
#
# Usage in flake.nix:
#   evalTests.x86_64-linux = import ./tests { inherit pkgs lib nixpkgs home-manager impermanence; };
{
  pkgs,
  lib,
  nixpkgs,
  home-manager,
  impermanence,
}: let
  testLib = import ./lib {inherit pkgs lib nixpkgs home-manager impermanence;};
in {
  # core/
  eval-core-boot = import ./eval/core/boot.nix {inherit pkgs testLib;};
  eval-core-locale = import ./eval/core/locale.nix {inherit pkgs testLib;};
  eval-core-networking = import ./eval/core/networking.nix {inherit pkgs testLib;};
  eval-core-nix = import ./eval/core/nix.nix {inherit pkgs testLib;};
  eval-core-users = import ./eval/core/users.nix {inherit pkgs testLib;};

  # graphics/
  eval-graphics-audio = import ./eval/graphics/audio.nix {inherit pkgs testLib;};
  eval-graphics-hyprland = import ./eval/graphics/hyprland.nix {inherit pkgs testLib;};
  eval-graphics-portal = import ./eval/graphics/portal.nix {inherit pkgs testLib;};
  eval-graphics-fonts = import ./eval/graphics/fonts/fonts.nix {inherit pkgs testLib;};

  # hardware/
  eval-hardware-bluetooth = import ./eval/hardware/bluetooth.nix {inherit pkgs testLib;};
  eval-hardware-cpu-intel = import ./eval/hardware/cpu-intel.nix {inherit pkgs testLib;};
  eval-hardware-gpu-nvidia = import ./eval/hardware/gpu-nvidia.nix {inherit pkgs testLib;};

  # home/
  eval-home-home = import ./eval/home/home.nix {inherit pkgs testLib;};

  # impermanence/
  eval-impermanence = import ./eval/impermanence/impermanence.nix {inherit pkgs testLib;};
}
