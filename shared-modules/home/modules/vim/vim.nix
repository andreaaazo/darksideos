{pkgs, ...}: {
  # Keep a minimal terminal editor available for commit messages, recovery, and remote shells.
  home-manager.users.andrea.home.packages = [pkgs.vim];
}
