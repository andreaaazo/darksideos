{pkgs, ...}: {
  # Install Grim utility in the user profile.
  home-manager.users.andrea.home.packages = [pkgs.grim];
}
