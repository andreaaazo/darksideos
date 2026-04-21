{pkgs, ...}: {
  # Install Slurp utility in the user profile.
  home-manager.users.andrea.home.packages = [pkgs.slurp];
}
