# User-level module collection, wired as a NixOS module so mixed system/HM modules can stay standalone.
{
  # Import every Home module as a standalone NixOS wrapper.
  imports = [
    ./git
    ./hyprland
    ./hyprpaper
    ./grim
    ./features/screenshot
    ./slurp
    ./wl-clipboard
    ./kitty
    ./zen-browser
    ./hyprpicker
    ./spotify
    ./vim
  ];
}
