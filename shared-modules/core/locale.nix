# Locale configuration shared across all hosts.
# Host-specific overrides belong in hosts/<hostname>/default.nix.
{
  # System clock set to CET/CEST with automatic DST switching.
  time.timeZone = "Europe/Zurich";

  i18n = {
    # System language is English.
    defaultLocale = "en_US.UTF-8";
    # Generate only the locales actually used by this system.
    # Reduces locale archive size and avoids unnecessary locale payload.
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "de_CH.UTF-8/UTF-8"
    ];
    extraLocaleSettings = {
      # Date/time formatting follows Swiss-German conventions
      LC_TIME = "de_CH.UTF-8";
      # Currency formatting uses Swiss conventions
      LC_MONETARY = "de_CH.UTF-8";
      # Metric system as measurement standard
      LC_MEASUREMENT = "de_CH.UTF-8";
      # Number formatting uses Swiss conventions
      LC_NUMERIC = "de_CH.UTF-8";
      # Default paper size is A4
      LC_PAPER = "de_CH.UTF-8";
    };
  };

  # TTY Console keyboard layout
  console.keyMap = "sg"; # Swiss German

  # Graphical sessions (X11/Wayland) keyboard layout
  services.xserver.xkb = {
    layout = "ch";
    variant = "de";
  };
}
