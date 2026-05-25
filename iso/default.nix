# Minimal live ISO configuration for the future DarksideOS installer.
{
  disko,
  lib,
  pkgs,
  self,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;

  installerRuntimePackages = with pkgs; [
    coreutils
    disko.packages.${system}.default
    findutils
    git
    gnugrep
    gnused
    jq
    util-linux
    nixos-install-tools
    age
    sops
    mkpasswd
    nix
    gum
  ];

  installerOperatorPackages = with pkgs; [
    sudo
    vim
  ];

  darksideosInstaller = pkgs.writeShellApplication {
    name = "darksideos-install";
    runtimeInputs = installerRuntimePackages;
    text = ''
      export DARKSIDEOS_SOURCE=${self}
      export DARKSIDEOS_INSTALLER_ROOT=${./scripts}
      export DARKSIDEOS_INSTALLER_SHARED=${./scripts/shared}
      export DARKSIDEOS_INSTALLER_DOMAIN=${./scripts/domain}
      export DARKSIDEOS_INSTALLER_PRESENTATION=${./scripts/presentation}
      export DARKSIDEOS_INSTALLER_APPLICATION=${./scripts/application}
      export DARKSIDEOS_INSTALLER_DTOS=${./scripts/application/dtos}
      export DARKSIDEOS_INSTALLER_SERVICES=${./scripts/application/services}
      export DARKSIDEOS_INSTALLER_USE_CASES=${./scripts/application/use-cases}
      export DARKSIDEOS_INSTALLER_INFRASTRUCTURE=${./scripts/infrastructure}
      export DARKSIDEOS_INSTALLER_REPOSITORIES=${./scripts/infrastructure/repositories}
      export DARKSIDEOS_INSTALLER_SYSTEM=${./scripts/infrastructure/system}
      export DARKSIDEOS_INSTALLER_GENERATORS=${./scripts/infrastructure/generators}
      ${builtins.readFile ./scripts/darksideos-install.sh}
    '';
  };
in {
  networking.hostName = "darksideos-installer";
  networking.firewall.allowedTCPPorts = lib.mkForce [];

  services.openssh.enable = lib.mkForce false;
  services.openssh.openFirewall = lib.mkForce false;
  systemd.services.nix-channel-init.enable = lib.mkForce false;
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

  image.fileName = "darksideos-installer.iso";
  isoImage.volumeID = "DARKSIDEOS";

  environment.systemPackages =
    [
      darksideosInstaller
    ]
    ++ installerRuntimePackages
    ++ installerOperatorPackages;

  programs.bash.shellInit = ''
    echo "DarksideOS installer ISO"
    echo "Run: sudo darksideos-install"
  '';
}
