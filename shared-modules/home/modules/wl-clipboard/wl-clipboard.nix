{pkgs, ...}: {
  # Install wl-clipboard tools for Wayland clipboard read/write operations.
  home.packages = [pkgs."wl-clipboard"];
}
