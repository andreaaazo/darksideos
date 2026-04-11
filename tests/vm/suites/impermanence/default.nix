# VM suites for shared-modules/impermanence/*
{vmLib}: {
  vm-impermanence = import ./impermanence.nix {inherit vmLib;};
}
