{pkgs, ...} : {
home-manager.users.andrea.programs.btop = {
enable = true;
package = pkgs.btop;


};

}
