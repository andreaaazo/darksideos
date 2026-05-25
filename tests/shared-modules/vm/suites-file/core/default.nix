# VM suites for shared-modules/core/*
{vmLib}: {
  vm-core-boot = import ./boot.nix {inherit vmLib;};
  vm-core-locale = import ./locale.nix {inherit vmLib;};
  vm-core-nix = import ./nix.nix {inherit vmLib;};
  vm-core-networking = import ./networking.nix {inherit vmLib;};
  vm-core-secrets = import ./secrets.nix {inherit vmLib;};
  vm-core-users = import ./users.nix {inherit vmLib;};
}
