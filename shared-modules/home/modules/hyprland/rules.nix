{
  # Hyprland window rule list applied at runtime.
  wayland.windowManager.hyprland.settings.windowrule = [
    # SPOTIFY OPACITY
    # Forces Spotify to render with fixed transparency in both active and inactive states, overriding any opacity settings
    "opacity 0.80 override 0.80 override, match:^(spotify)$"
    # KITTY OPACITY
    # Forces Kitty terminal windows to render fully opaque, letting Kitty handle its own
    "opacity 1.00 override 1.00 override, class:^(kitty)$"
    # FULLSCREEN SHADOW DISABLE
    # Disables shadows on fullscreen windows to avoid edge glow and save GPU work
    "noshadow, fullscreen:1"
  ];
}
