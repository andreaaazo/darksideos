# Hyprland compositor and Wayland session setup.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{ ... }:
{
  programs.hyprland = {
    # Installs Hyprland compositor, configures the Wayland session, and sets required environment variables.
    enable = true;
    # Disables the X11 compatibility layer so legacy apps (Electron, Steam, old GTK/Qt) can't run inside Wayland.
    xwayland.enable = false;
  };

  # Enables PolicyKit authentication agent required by Hyprland to access input devices, GPU, and perform privileged actions without root.
  security.polkit.enable = true;

  environment.sessionVariables = {
    # Tells apps the current session is Wayland so they choose the correct rendering backend.
    XDG_SESSION_TYPE = "wayland";
    # Tells XDG portals and desktop-aware apps which compositor is running (used for portal backend selection).
    XDG_CURRENT_DESKTOP = "Hyprland";
  };
}
