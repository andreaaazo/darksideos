{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../grim
    ../../slurp
    ../../wl-clipboard
  ];

  # SCREENSHOT: Select area (slurp), capture it (grim), and pipe to clipboard (wl-copy)
  # Key: [SUPER] + [SHIFT] + [S](creenshot)
  wayland.windowManager.hyprland.settings.bind = lib.mkAfter [
    "$mainMod SHIFT, S, exec, ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs."wl-clipboard"}/bin/wl-copy"
  ];
}
