{
  # Host-specific monitor tuning for Andrea's Hyprland profile.
  home-manager.users.andrea.wayland.windowManager.hyprland.settings.monitorv2 = {
    # PORT
    # Target DisplayPort-3
    output = "DP-3";

    # RESOLUTION
    # 4K resolution @ 60Hz
    mode = "3840x2160@60";

    # SCALE
    # Fractional scaling (x1.07) to enlarge UI elements for better readability
    scale = 1.07;

    # COLOR DEPTH
    # 10-bit color depth to reduce banding in gradients
    bitdepth = 10;

    # FEATURE FLAGS
    # HDR automatic and enable Wide Color Gamut
    supports_hdr = 0;
    supports_wide_color = 1;

    # COLOR PROFILE
    # Use DCI-P3 color space for richer colors compared to sRGB
    cm = "dcip3";

    # LUMINANCE SETTINGS
    # Set SDR EOTF parameters for better SDR content rendering
    sdr_eotf = 1;
  };
}
