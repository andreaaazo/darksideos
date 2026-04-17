{
  # Hyprland visual style and decoration namespace.
  wayland.windowManager.hyprland.settings = {
    # General tiling and border behavior.
    general = {
      # INNER GAPS
      # Removes spacing between tiled windows to keep layouts dense and edge-aligned
      gaps_in = 0;
      # OUTER GAPS
      # Adds padding between windows and screen edges for visual breathing room
      gaps_out = 16;
      # BORDER THICKNESS
      # Slightly thicker borders improves window separation
      border_size = 3;
      # ACTIVE BORDER COLOR
      # Color of the border for the focused window
      col.active_border = "rgba(7d00e0ee) rgba(5628F3ee) 45deg";
      # INACTIVE BORDER COLOR
      # Color of the border for unfocused windows
      col.inactive_border = "rgba(706C79ee)";
      # TILING LAYOUT
      # Sets the default layout to 'dwindle' for dynamic window arrangement
      layout = "dwindle";
    };

    # WINDOW DECORATION
    # ------------------

    decoration = {
      # CORNER ROUNDING
      # Rounding of window corners
      rounding = 8;
      # ROUNDING CURVE
      # Higher values create a more pronounced rounding effect
      rounding_power = 4;
      # ACTIVE WINDOW OPACITY
      # Opacity for the focused window (1 = fully opaque)
      active_opacity = 1;
      # INACTIVE WINDOW OPACITY
      # Opacity for unfocused windows (0.88 = slightly transparent)
      inactive_opacity = 0.88;

      # SHADOW SETTINGS
      # ------------------

      shadow = {
        # SHADOW ENABLE
        # Enables shadows for windows
        enabled = true;
        # SHADOW SPREAD
        # Distance the shadow extends from the window
        range = 16;
        # SHADOW SOFTNESS
        # Higher values create softer shadows
        render_power = 4;
        # SHADOW EXCLUSIONS
        # Prevents self-shadow artifacts on the focused window to keep edges crisp
        ignore_window = true;
      };

      # BLUR SETTINGS
      # ----------------------

      blur = {
        # BLUR ENABLE
        # Enables background blur for windows
        enabled = true;
        # BLUR RADIUS
        # Size of the blur effect (higher values create a stronger blur)
        size = 8;
        # BLUR QUALITY PASSES
        # Multiple passes reduce banding and blockiness in the blur
        passes = 3;
        # OPTIMIZED BLUR PIPELINE
        # Uses newer blur optimizations for better performance and quality
        new_optimizations = true;
        # OPACITY-AWARE BLUR
        # Keeps blur consistent even when window opacity changes, avoiding "double-dim"
        ignore_opacity = true;
        # XRAY MODE
        # Disabled to avoid over-clarifying backgrounds
        xray = false;
        # FILM GRAIN
        # Adds noise to break up blur banding on smooth gradients
        noise = 0.04;
        # CONTRAST
        # Adjusts contrast of the blurred background (1.0 = normal contrast)
        contrast = 1.0;
        # VIBRANCY
        # Increases color saturation in the blurred background for a more vivid look
        vibrancy = 0.1696;
        # BRIGHTNESS
        # Adjusts brightness of the blurred background (0.8 = slightly dimmed)
        brightness = 0.8;
      };
    };
  };
}
