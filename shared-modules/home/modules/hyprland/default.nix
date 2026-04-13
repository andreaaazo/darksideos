{
  # Manage Hyprland entirely through Home Manager options (no raw conf file source).
  wayland.windowManager.hyprland.enable = true;

  imports = [
    ./animations.nix
    ./bindings.nix
    ./cursor.nix
    ./input.nix
    ./rules.nix
    ./system.nix
    ./theme.nix
  ];
}
