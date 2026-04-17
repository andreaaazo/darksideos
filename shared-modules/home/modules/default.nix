# User-level Home Manager modules (shell, git, editor, etc.).
# Each module is a standalone file imported here.
{...}: {
  # Import the shared Home Manager module set for interactive applications and UX features.
  imports = [
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
  ];
}
