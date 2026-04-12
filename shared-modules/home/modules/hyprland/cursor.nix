{
  # Cursor size is user policy; theme stays system policy.
  home.sessionVariables = {
    XCURSOR_SIZE = "24";
    HYPRCURSOR_SIZE = "24";
  };

  # Ensure Hyprland session receives cursor size even when shell profile is not sourced.
  wayland.windowManager.hyprland.settings.env = [
    "XCURSOR_SIZE,24"
    "HYPRCURSOR_SIZE,24"
  ];
}
