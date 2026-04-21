{
  # Hyprland window rule list applied at runtime.
  wayland.windowManager.hyprland.settings.windowrule = [
    # Keep Spotify readable without relying on deprecated windowrulev2 matcher syntax.
    "opacity 0.80 override 0.80 override, match:class ^(spotify)$"
    # Keep Kitty fully opaque so terminal rendering stays sharp and deterministic.
    "opacity 1.00 override 1.00 override, match:class ^(kitty)$"
    # Disable fullscreen shadows to avoid edge glow and save GPU work.
    "no_shadow on, match:fullscreen true"
  ];
}
