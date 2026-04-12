{
  pkgs,
  testLib,
}:
import ./google-chrome.nix {inherit pkgs testLib;}
