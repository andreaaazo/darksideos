{pkgs, ...}: {
  # Install Kitty terminal emulator in the user profile.
  home-manager.users.andrea.home.packages = [pkgs.kitty];

  # Hyprland keybinding list to launch terminal-related actions.
  home-manager.users.andrea.wayland.windowManager.hyprland.settings.bind = [
    # TERMINAL: Launch the default terminal emulator (kitty)
    # Key: [SUPER] + [T](erminal)
    "$mainMod, T, exec, ${pkgs.kitty}/bin/kitty"
  ];
}
