{pkgs, ...}: {
  # Install wl-clipboard tools for Wayland clipboard read/write operations.
  home-manager.users.andrea.home.packages = [pkgs."wl-clipboard"];
}
