# VM suites for shared-modules/hardware/*
{vmLib}: {
  vm-hardware-audio = import ./audio.nix {inherit vmLib;};
  vm-hardware-bluetooth = import ./bluetooth.nix {inherit vmLib;};
  vm-hardware-cpu-base = import ./cpu-base.nix {inherit vmLib;};
  vm-hardware-cpu-amd = import ./cpu-amd.nix {inherit vmLib;};
  vm-hardware-cpu-intel = import ./cpu-intel.nix {inherit vmLib;};
  vm-hardware-gpu-nvidia = import ./gpu-nvidia.nix {inherit vmLib;};
}
