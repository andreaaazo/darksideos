# Desktop environment: Hyprland on Wayland.
# System-level enablement only — keybinds, appearance, and window rules
# belong in Home Manager (shared-modules/home/modules/).
#
# No display manager — login via TTY, launch Hyprland manually or via shell profile.
{...}: {
  # Import the system graphics baseline modules.
  imports = [
    ./hyprland.nix
    ./portal.nix
    ./fonts
  ];
}
