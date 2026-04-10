# System-wide font stack and fontconfig defaults.
# Default NixOS fonts are disabled — only explicitly declared fonts exist.
{pkgs, ...}: let
  # Builds a minimal Nix package from a raw font file (no compiler needed, hence NoCC).
  apple-emoji = pkgs.stdenvNoCC.mkDerivation {
    # Package name in the nix store (used for identification, not installation logic).
    pname = "apple-color-emoji";
    # Version string matching the GitHub release tag (informational, helps track which release is installed).
    version = "macos-26-20260219-2aa12422";
    # Downloads a file from a URL and verifies its integrity against the provided hash (fails if the file changes upstream).
    src = pkgs.fetchurl {
      url = "https://github.com/samuelngs/apple-emoji-ttf/releases/download/macos-26-20260219-2aa12422/AppleColorEmoji-Linux.ttf";
      # Cryptographic hash ensuring the downloaded file is exactly the expected one (determinism guarantee).
      hash = "sha256:535a043af04706d24471059e64745bfc80d6617ada2eea3435dc5620dc0f5318";
    };

    # Tells Nix the source is a raw file, not an archive — skip extraction (.ttf is not a tarball).
    dontUnpack = true;
    # Copies the downloaded .ttf into the standard font directory inside the nix store path.
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      cp $src $out/share/fonts/truetype/AppleColorEmoji.ttf
    '';
  };
in {
  fonts = {
    # Disables NixOS default fonts (DejaVu, Liberation, etc.) — only explicitly declared fonts exist on the system.
    enableDefaultPackages = false;

    packages = [
      # Monospace Nerd font for terminals, code editors, and any app requesting a fixed-width typeface.
      pkgs.nerd-fonts.jetbrains-mono
      # Sans-serif body font optimized for screen rendering, UI, and digital interfaces.
      pkgs.inter
      # The custom-built package defined above, providing Apple-style color emoji system-wide.
      apple-emoji
      # Builds an inline Nix package that copies committed DIN Next .otf files into the nix store font directory.
      (pkgs.runCommand "din-next" {} ''
        mkdir -p $out/share/fonts/opentype
        cp ${./din-next}/*.otf $out/share/fonts/opentype/
      '')
    ];

    fontconfig.defaultFonts = {
      # When any app requests "monospace" font family, fontconfig resolves to JetBrains Nerd Font.
      monospace = ["JetBrainsMono Nerd Font"];
      # When any app requests "sans-serif" font family, fontconfig resolves to Inter.
      sansSerif = ["Inter"];
      # When any app requests "serif" font family, fontconfig falls back to Inter (no dedicated serif font installed).
      serif = ["Inter"];
      # When any app needs to render emoji, fontconfig resolves to Apple Color Emoji.
      emoji = ["Apple Color Emoji"];
    };

    fontconfig = {
      # Reject legacy bitmap fonts to keep rendering modern and avoid obsolete font fallbacks.
      allowBitmaps = false;
      # Enforce deterministic system font policy; do not load per-user fontconfig overrides.
      includeUserConf = false;
    };
  };
}
