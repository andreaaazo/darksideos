{pkgs, ...}: {
  home.packages = [pkgs.spotify];

  wayland.windowManager.hyprland.settings.bind = [
    # SPOTIFY: Launch Spotify natively on Wayland
    # Key: [SUPER] + [S](potify)
    "$mainMod, S, exec, ${pkgs.spotify}/bin/spotify --ozone-platform=wayland --enable-features=UseOzonePlatform"
  ];
}
