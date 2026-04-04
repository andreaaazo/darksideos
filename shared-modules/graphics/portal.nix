# XDG Desktop Portals for sandboxed screen capture, file dialogs, and D-Bus services.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{pkgs, ...}: {
  xdg.portal = {
    # Enables the XDG Desktop Portal D-Bus service that apps use for sandboxed access to screen capture, file dialogs, and notifications.
    enable = true;

    extraPortals = with pkgs; [
      # Hyprland-native portal backend for screen sharing, window/output selection, and compositor integration.
      xdg-desktop-portal-hyprland
      # GTK portal backend that renders "Open file" / "Save as" dialogs and print dialogs for all apps.
      xdg-desktop-portal-gtk
    ];
  };

  # Enables D-Bus system message bus required by XDG portals, polkit, NetworkManager, and most desktop services to communicate.
  services.dbus.enable = true;
}
