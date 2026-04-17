{
  config,
  lib,
  pkgs,
  zenBrowser,
  ...
}: {
  # Import Zen Browser Home Manager module from external flake (twilight channel for reproducible artifacts).
  imports = [zenBrowser.homeModules.twilight];

  # Declarative Zen Browser program policy exposed by the imported Home Manager module.
  programs.zen-browser = {
    # Enable Zen Browser and generate wrapped package/profile integration.
    enable = true;
    # Register Zen as default browser for URL schemes and common web MIME types.
    setAsDefaultBrowser = true;
  };

  # Hyprland keybinding list to launch browser actions.
  wayland.windowManager.hyprland.settings.bind = lib.mkAfter [
    # ZEN BROWSER: Launch Zen Browser with native Wayland support
    # Key: [SUPER] + [I](nternet)
    "$mainMod, I, exec, ${pkgs.lib.getExe config.programs.zen-browser.package} --ozone-platform=wayland --enable-features=UseOzonePlatform"
  ];
}
