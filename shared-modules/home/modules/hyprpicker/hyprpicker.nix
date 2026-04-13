{pkgs, ...}: {
  home.packages = [pkgs.hyprpicker];

  wayland.windowManager.hyprland.settings.bind = [
    # COLOR PICKER: Select a pixel and immediately copy the HEX code to clipboard
    # Key: [SUPER] + [P](icker)
    "$mainMod SHIFT, P, exec, ${pkgs.hyprpicker}/bin/hyprpicker -a"
  ];
}
