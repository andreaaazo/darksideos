{pkgs, ...}: {
  # Install Kitty terminal emulator in the user profile.
  home-manager.users.andrea.home.packages = [pkgs.kitty];

  home-manager.users.andrea.programs.kitty = {
    enable = true;
	settings = {
		font_family = "JetBrainsMono Nerd Font";
		bold_font = "auto";
		italic_font = "auto";
		bold_italic_font = "auto";
		font_size = 16;
		adjust_line_height = "110%";
		window_padding_width = 16;
		enable_audio_bell = "no";
		confirm_os_window_close = 0;
		hide_window_decorations = "yes";
		background_opacity = 0.6;
		cursor_shape = "beam";
		cursor_blink_interval = 0.5;
		cursor_stop_blinking_after = 15.0;
		
		background = "#282a36";
foreground = "#f8f8f2";
selection_foreground = "#ffffff";
selection_background = "#44475a";
url_color = "#8be9fd";
color0 = "#21222c";
color8 = "#6272a4";
color1 = "#ff5555";
color9 = "#ff6e6e";
color2 = "#50fa7b";
color10 = "#69ff94";
color3 = "#f1fa8c";
color11 = "#ffffa5";
color4 = "#bd93f9";
color12 = "#d6acff";
color5 = "#ff79c6";
color13 = "#ff92df";
color6 = "#8be9fd";
color7 = "#f8f8f2";
color15 = "#ffffff";
cursor = "#f8f8f2";
cursor_text_color = "background";
active_tab_foreground = "#282a36";
active_tab_background = "#f8f8f2";
inactive_tab_foreground = "#282a36";
inactive_tab_background = "#6272a4";
mark1_foreground = "#282a36";
mark1_background = "#ff5555";
active_border_color = "#f8f8f2";
inactive_border_color = "#6272a4";











};


};

  # Hyprland keybinding list to launch terminal-related actions.
  home-manager.users.andrea.wayland.windowManager.hyprland.settings.bind = [
    # TERMINAL: Launch the default terminal emulator (kitty)
    # Key: [SUPER] + [T](erminal)
    "$mainMod, T, exec, ${pkgs.kitty}/bin/kitty"
  ];
}
