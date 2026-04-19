{pkgs, ...}: {
  # Install Grim utility in the user profile.
  home.packages = [pkgs.grim];
}
