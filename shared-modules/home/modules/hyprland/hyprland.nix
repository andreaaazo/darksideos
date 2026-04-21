{
  # Manage Hyprland entirely through Home Manager options while keeping the module importable at NixOS level.
  home-manager.users.andrea = {
    # Enable the compositor through the official Home Manager option, not a raw generated config file.
    wayland.windowManager.hyprland.enable = true;

    # Import all Hyprland submodules inside the Home Manager namespace they are written for.
    imports = [
      ./animations.nix
      ./bindings.nix
      ./cursor.nix
      ./input.nix
      ./rules.nix
      ./system.nix
      ./theme.nix
    ];
  };
}
