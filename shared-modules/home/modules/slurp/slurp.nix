{pkgs, ...}: {
  # Install Slurp utility in the user profile.
  home.packages = [pkgs.slurp];
}
