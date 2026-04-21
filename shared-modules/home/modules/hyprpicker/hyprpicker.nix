{pkgs, ...}: {
  # Install Hyprpicker utility in the user profile.
  home-manager.users.andrea.home.packages = [pkgs.hyprpicker];

  # Hyprland keybinding list for color sampling actions.
  home-manager.users.andrea.wayland.windowManager.hyprland.settings.bind = [
    # COLOR PICKER: Select a pixel and immediately copy the HEX code to clipboard
    # Key: [SUPER] + [P](icker)
    "$mainMod SHIFT, P, exec, ${pkgs.hyprpicker}/bin/hyprpicker -a"
  ];
}
