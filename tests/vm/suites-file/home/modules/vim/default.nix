# VM test for shared-modules/home/modules/vim/default.nix.
{vmLib}: import ./vim.nix {inherit vmLib;}
