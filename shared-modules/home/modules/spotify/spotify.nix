{pkgs, ...}: {
  # Install Spotify desktop client in the user profile.
  home.packages = [pkgs.spotify];

  # Hyprland keybinding list to launch media applications.
  wayland.windowManager.hyprland.settings.bind = [
    # SPOTIFY: Launch Spotify natively on Wayland
    # Key: [SUPER] + [S](potify)
    "$mainMod, S, exec, ${pkgs.spotify}/bin/spotify --ozone-platform=wayland --enable-features=UseOzonePlatform"
  ];
}
