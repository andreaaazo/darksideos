# VM suites for shared-modules/home/*
{vmLib}: {
  vm-home-home = import ./home.nix {inherit vmLib;};
}
