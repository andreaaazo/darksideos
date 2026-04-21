let
  icmFile = "H7606WW_1002_834C420E_CMDEF.icm";
  icmTarget = "color/icc/${icmFile}";
  icmPath = "/home/andrea/.local/share/${icmTarget}";
in {
  home-manager.users.andrea = {
    # HM recreates this XDG profile link at activation; source is in /etc/nixos and store-backed, so no extra impermanence entry is needed.
    xdg.dataFile.${icmTarget}.source = ./icc/${icmFile};

    # Host-only Hyprland policy for vader's internal ProArt P16 panel and unmatched external displays.
    wayland.windowManager.hyprland.settings = {
      monitor = [
        # Empty output is the documented fallback rule; replace with eDP-1/desc once the panel name is confirmed if external ICC accuracy matters.
        ",preferred,auto,1.5,bitdepth,10,icc,${icmPath},vrr,3"
      ];

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
