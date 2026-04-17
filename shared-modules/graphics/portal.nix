# XDG Desktop Portals for sandboxed screen capture, file dialogs, and D-Bus services.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{pkgs, ...}: {
  # XDG portal namespace used by sandboxed desktop applications.
  xdg.portal = {
    # Enables the XDG Desktop Portal D-Bus service that apps use for sandboxed access to screen capture, file dialogs, and notifications.
    enable = true;
    # Force xdg-open to go through portal path for consistent sandbox-safe behavior.
    xdgOpenUsePortal = true;

    # Additional portal backends available to xdg-desktop-portal.
    extraPortals = with pkgs; [
      # Hyprland-native portal backend for screen sharing, window/output selection, and compositor integration.
      xdg-desktop-portal-hyprland
      # GTK portal backend that renders "Open file" / "Save as" dialogs and print dialogs for all apps.
      xdg-desktop-portal-gtk
    ];

    # Explicit backend routing for deterministic behavior on xdg-desktop-portal >= 1.17.
    config.common = {
      # Fallback backend order when no interface-specific mapping is provided.
      default = [
        "hyprland"
        "gtk"
      ];
      # Route screen casting requests to the Hyprland-native backend.
      "org.freedesktop.impl.portal.ScreenCast" = ["hyprland"];
      # Route screenshot requests to the Hyprland-native backend.
      "org.freedesktop.impl.portal.Screenshot" = ["hyprland"];
      # Route remote desktop requests to the Hyprland-native backend.
      "org.freedesktop.impl.portal.RemoteDesktop" = ["hyprland"];
      # Route file chooser dialogs to GTK backend for consistent UI behavior.
      "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
      # Route settings portal to GTK backend.
      "org.freedesktop.impl.portal.Settings" = ["gtk"];
    };
  };

  # Enables D-Bus system message bus required by XDG portals, polkit, NetworkManager, and most desktop services to communicate.
  services.dbus.enable = true;
}
