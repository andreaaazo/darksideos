# User-level Home Manager modules (shell, git, editor, etc.).
# Each module is a standalone file imported here.
{...}: {
  imports = [
    ./hyprland
    ./hyprpaper
    ./grim
    ./features/screenshot
    ./slurp
    ./wl-clipboard
    ./kitty
    ./google-chrome
    ./hyprpicker
    ./spotify
  ];
}
