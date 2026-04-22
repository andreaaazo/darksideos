{pkgs, ...}: {
  # Install Spotify desktop client in the user profile.
  home-manager.users.andrea.home.packages = [pkgs.spotify];

home-manager.users.andrea.home.persistence."/persist" = {directories = [
".config/spotify"
".cache/spotify/Default"
".cache/spotify/Users"
".cache/spotify/Storage"
];
files = [
".cache/spotify/Local State"

];
};
  # Hyprland keybinding list to launch media applications.
  home-manager.users.andrea.wayland.windowManager.hyprland.settings.bind = [
    # SPOTIFY: Launch Spotify natively on Wayland
    # Key: [SUPER] + [S](potify)
    "$mainMod, S, exec, ${pkgs.spotify}/bin/spotify --ozone-platform=wayland --enable-features=UseOzonePlatform"
  ];
}
