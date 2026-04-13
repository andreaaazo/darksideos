# Eval suites aggregator.
{
  pkgs,
  testLib,
}:
(import ./core {inherit pkgs testLib;})
// (import ./graphics {inherit pkgs testLib;})
// (import ./hardware {inherit pkgs testLib;})
// (import ./home {inherit pkgs testLib;})
// (import ./impermanence {inherit pkgs testLib;})
