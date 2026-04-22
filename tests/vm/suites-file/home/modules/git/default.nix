# VM test for shared-modules/home/modules/git/default.nix.
{vmLib}: import ./git.nix {inherit vmLib;}
