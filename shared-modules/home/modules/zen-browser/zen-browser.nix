{pkgs, ...}: {
  # Install Zen Browser in the user profile.
  home.packages = [pkgs."zen-browser"];

  # Hyprland keybinding list to launch browser actions.
  wayland.windowManager.hyprland.settings.bind = [
    # ZEN BROWSER: Launch Zen Browser with native Wayland support
    # Key: [SUPER] + [I](nternet)
    "$mainMod, I, exec, ${pkgs.lib.getExe pkgs."zen-browser"} --ozone-platform=wayland --enable-features=UseOzonePlatform"
  ];
}
