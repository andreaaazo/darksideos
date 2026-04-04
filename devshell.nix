# Development shell with Nix tooling.
# Provides formatter, linter, dead code finder, and LSP.
{pkgs}:
pkgs.mkShell {
  packages = with pkgs; [
    alejandra # Nix formatter
    statix # Nix linter (anti-patterns)
    deadnix # Dead code finder (unused bindings, inputs)
    nixd # Nix LSP for editor integration
  ];
}
