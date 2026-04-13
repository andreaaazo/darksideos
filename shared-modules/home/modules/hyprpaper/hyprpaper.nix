{pkgs, ...}: {
  # Keep hyprpaper binary available in user profile for manual control/debug.
  home.packages = [pkgs.hyprpaper];

  # Use official Home Manager hyprpaper module for declarative config + service wiring.
  services.hyprpaper = {
    enable = true;
    settings = {
      wallpaper = [
        {
          # Empty monitor selector applies to all monitors.
          monitor = "";
          path = "${./wallpaper/wallpaper.jpg}";
          fit_mode = "cover";
        }
      ];
      splash = false;
    };
  };
}
