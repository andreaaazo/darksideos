# VM suites aggregator for full module-integration and full-stack tests.
{vmLib}: {
  vm-module-core = import ./module-core.nix {inherit vmLib;};
  vm-module-graphics = import ./module-graphics.nix {inherit vmLib;};
  vm-module-hardware = import ./module-hardware.nix {inherit vmLib;};
  vm-module-home = import ./module-home.nix {inherit vmLib;};
  vm-module-impermanence = import ./module-impermanence.nix {inherit vmLib;};
  vm-stack-shared = import ./stack-shared.nix {inherit vmLib;};
}
