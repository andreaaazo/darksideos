# Hyprland compositor and Wayland session setup.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{pkgs, ...}: {
  programs.hyprland = {
    # Install and enable Hyprland compositor.
    enable = true;
    # Pure Wayland baseline: no X11 compatibility layer.
    xwayland.enable = false;
    # Use modern systemd-aware session manager flow.
    withUWSM = true;
    # Keep systemd user manager PATH untouched by Hyprland module helper.
    systemd.setPath.enable = false;
    # Explicit package selection.
    package = pkgs.hyprland;
    # Explicit Hyprland portal backend package.
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };

  # PolicyKit for privileged desktop actions without root session.
  security.polkit.enable = true;

  environment.sessionVariables = {
    # Explicit Wayland session identity.
    XDG_SESSION_TYPE = "wayland";
    # Desktop identity for portals and desktop-aware apps.
    XDG_CURRENT_DESKTOP = "Hyprland";
    # Chromium/Electron Ozone Wayland backend toggle.
    NIXOS_OZONE_WL = "1";
    # Firefox native Wayland backend toggle.
    MOZ_ENABLE_WAYLAND = "1";
  };
}
