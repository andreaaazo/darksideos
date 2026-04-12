{pkgs, ...}: {
  home.packages = [pkgs.kitty];

  wayland.windowManager.hyprland.settings.bind = [
    # TERMINAL: Launch the default terminal emulator (kitty)
    # Key: [SUPER] + [T](erminal)
    "$mainMod, T, exec, ${pkgs.kitty}/bin/kitty"
  ];
}
