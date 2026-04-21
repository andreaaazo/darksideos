# VM suites for shared-modules/home/modules/*
{vmLib}: {
  vm-home-modules-features-screenshot = import ./features/screenshot {inherit vmLib;};
  vm-home-modules-git = import ./git {inherit vmLib;};
  vm-home-modules-grim = import ./grim {inherit vmLib;};
  vm-home-modules-hyprland = import ./hyprland {inherit vmLib;};
  vm-home-modules-hyprpaper = import ./hyprpaper {inherit vmLib;};
  vm-home-modules-hyprpicker = import ./hyprpicker {inherit vmLib;};
  vm-home-modules-kitty = import ./kitty {inherit vmLib;};
  vm-home-modules-slurp = import ./slurp {inherit vmLib;};
  vm-home-modules-spotify = import ./spotify {inherit vmLib;};
  vm-home-modules-vim = import ./vim {inherit vmLib;};
  vm-home-modules-wl-clipboard = import ./wl-clipboard {inherit vmLib;};
  vm-home-modules-zen-browser = import ./zen-browser {inherit vmLib;};
}
