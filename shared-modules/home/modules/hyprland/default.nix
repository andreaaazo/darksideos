{
  # Manage Hyprland entirely through Home Manager options (no raw conf file source).
  wayland.windowManager.hyprland = {
    enable = true;
    # Keep Home Manager package policy aligned with the system Hyprland module:
    # pure Wayland baseline, no XWayland compatibility layer.
    xwayland.enable = false;
    # Keep the current declarative Hyprlang settings explicit until the Lua
    # configuration migration is implemented as a separate, tested change.
    configType = "hyprlang";
  };

  # Import all Hyprland submodules (bindings, visuals, behavior, and session tuning).
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
