# VM suites for shared-modules/hardware/*
{vmLib}: {
  vm-hardware-bluetooth = import ./bluetooth.nix {inherit vmLib;};
  vm-hardware-cpu-intel = import ./cpu-intel.nix {inherit vmLib;};
  vm-hardware-gpu-nvidia = import ./gpu-nvidia.nix {inherit vmLib;};
}
