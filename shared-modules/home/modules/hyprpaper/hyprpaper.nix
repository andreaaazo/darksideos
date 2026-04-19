{pkgs, ...}: {
  # Keep hyprpaper binary available in user profile for manual control/debug.
  home.packages = [pkgs.hyprpaper];

  # Use official Home Manager hyprpaper module for declarative config + service wiring.
  services.hyprpaper = {
    # Enable hyprpaper user service managed by Home Manager.
    enable = true;
    # Hyprpaper runtime settings passed to generated configuration.
    settings = {
      # Wallpaper mapping list (monitor selector + image path + fit strategy).
      wallpaper = [
        {
          # Empty monitor selector applies to all monitors.
          monitor = "";
          # Wallpaper asset path tracked in this module directory.
          path = "${./wallpaper/wallpaper.jpg}";
          # Scale image to fully cover monitor area.
          fit_mode = "cover";
        }
      ];
      # Disable startup splash to keep background daemon initialization clean.
      splash = false;
    };
  };
}
