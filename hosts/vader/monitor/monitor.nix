let
  icmFile = "H7606WW_1002_834C420E_CMDEF.icm";
  icmTarget = "color/icc/${icmFile}";
  icmPath = "/home/andrea/.local/share/${icmTarget}";
in {
  home-manager.users.andrea = {
    # HM recreates this XDG profile link at activation; source is in /etc/nixos and store-backed, so no extra impermanence entry is needed.
    xdg.dataFile.${icmTarget}.source = ./icc/${icmFile};

    # Host-only Hyprland policy for vader's internal ProArt P16 panel.
    wayland.windowManager.hyprland.settings = {
      monitor = {
        # Empty output is Hyprland's documented fallback rule for every monitor without a more specific match.
        output = "";
        # Use the panel preferred timing so firmware/native refresh stays source-of-truth.
        mode = "preferred";
        # Let Hyprland place matching monitors to avoid overlap when external panels are hotplugged.
        position = "auto";
        # 3840x2400 at 1.5 gives a deterministic 2560x1600 logical workspace.
        scale = 1.5;
        # Prefer 10-bit scanout path to reduce banding on the OLED panel.
        bitdepth = 10;
        # Hyprland expects an absolute profile path, while Home Manager owns the target link.
        icc = icmPath;
        # Restrict VRR to fullscreen video/game paths to avoid desktop timing jitter.
        vrr = 3;
      };

      render = {
        # Enable Hyprland's color-management pipeline so ICC and HDR policy are actually consumed.
        cm_enabled = true;
        # Let fullscreen content bypass SDR tone mapping when direct display passthrough is valid.
        cm_fs_passthrough = 2;
        # Switch into HDR mode only when HDR content is detected by the compositor.
        cm_auto_hdr = 1;
        # Send SDR/HDR content-type hints to the display link for correct downstream intent signaling.
        send_content_type = true;
        # Allow fullscreen/game direct scanout when Hyprland can skip composition safely.
        direct_scanout = 2;
        # Use non-shader color management where supported while keeping compositor fallback available.
        non_shader_cm = 2;
      };
    };
  };
}
