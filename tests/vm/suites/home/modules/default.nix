# VM suites for shared-modules/home/modules/*
{vmLib}: {
  vm-home-modules-hyprland = import ./hyprland {inherit vmLib;};
}
