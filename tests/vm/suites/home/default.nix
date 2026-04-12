# VM suites for shared-modules/home/*
{vmLib}:
  (import ./modules {inherit vmLib;})
  // {
    vm-home-home = import ./home.nix {inherit vmLib;};
  }
