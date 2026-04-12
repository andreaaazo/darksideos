{pkgs, ...}: {
  home.packages = [pkgs."google-chrome"];

  wayland.windowManager.hyprland.settings.bind = [
    # GOOGLE CHROME: Launch Google Chrome with native Wayland support
    # Key: [SUPER] + [I](nternet)
    "$mainMod, I, exec, ${pkgs."google-chrome"}/bin/google-chrome-stable --ozone-platform=wayland --enable-features=UseOzonePlatform"
  ];
}
