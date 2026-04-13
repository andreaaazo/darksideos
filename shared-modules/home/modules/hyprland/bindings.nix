{pkgs, ...}: let
  hyprWindowMove = pkgs.writeShellScriptBin "hypr-window-move" ''
    export PATH=${pkgs.lib.makeBinPath [pkgs.hyprland pkgs.jq]}:$PATH
    ${builtins.readFile ./scripts/window_move.sh}
  '';

  hyprWindowResize = pkgs.writeShellScriptBin "hypr-window-resize" ''
    export PATH=${pkgs.lib.makeBinPath [pkgs.hyprland pkgs.jq]}:$PATH
    ${builtins.readFile ./scripts/window_resize.sh}
  '';
in {
  wayland.windowManager.hyprland.settings = {
    # BINDINGS
    "$mainMod" = "SUPER";

    bind = [
      # WINDOW FOCUS
      # ------------------
      # FOCUS MOVEMENT: Move focus between windows using Vim-style keys (h/j/k/l)
      # Key: [SUPER] + [h/j/k/l]
      "$mainMod, h, movefocus, l"
      "$mainMod, l, movefocus, r"
      "$mainMod, k, movefocus, u"
      "$mainMod, j, movefocus, d"
      # CYCLE WINDOWS: Cycle focus through windows on the current workspace
      # Key: [SUPER] + [Tab]
      "$mainMod, Tab, cyclenext"

      # WINDOW MOVE
      # ------------------
      # MOVE TO WORKSPACE: Move the active window to a specific workspace
      # Key: [SUPER] + [SHIFT] + [1-9]
      "$mainMod SHIFT, 1, movetoworkspace, 1"
      "$mainMod SHIFT, 2, movetoworkspace, 2"
      "$mainMod SHIFT, 3, movetoworkspace, 3"
      "$mainMod SHIFT, 4, movetoworkspace, 4"
      "$mainMod SHIFT, 5, movetoworkspace, 5"
      "$mainMod SHIFT, 6, movetoworkspace, 6"
      "$mainMod SHIFT, 7, movetoworkspace, 7"
      "$mainMod SHIFT, 8, movetoworkspace, 8"
      "$mainMod SHIFT, 9, movetoworkspace, 9"
      # KEYBOARD MOVE: Move windows precisely using custom scripts
      # Key: [SUPER] + [SHIFT] + [h/j/k/l] for directional movement, [c] for centering
      "$mainMod SHIFT, H, exec, ${hyprWindowMove}/bin/hypr-window-move l"
      "$mainMod SHIFT, L, exec, ${hyprWindowMove}/bin/hypr-window-move r"
      "$mainMod SHIFT, K, exec, ${hyprWindowMove}/bin/hypr-window-move u"
      "$mainMod SHIFT, J, exec, ${hyprWindowMove}/bin/hypr-window-move d"
      "$mainMod SHIFT, C, exec, ${hyprWindowMove}/bin/hypr-window-move c"

      # WINDOW STATE
      # ------------------
      # TOGGLE FULLSCREEN: Toggle fullscreen state for the active window
      # Key: [SUPER] + [F](ullscreen)
      "$mainMod, F, fullscreen"
      # TOGGLE PIN: Toggle pin state to floating window to show on all workspaces (Always On Top)
      # Key: [SUPER] + [P](in)
      "$mainMod, P, pin"
      # CLOSE WINDOW: Kill the active window immediately
      # Key: [SUPER] + [Q](uit)
      "$mainMod, Q, killactive"

      # WORKSPACES
      # ----------------------
      # SWITCH WORKSPACE: Navigate to a specific workspace directly
      # Key: [SUPER] + [1-9]
      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"

      # SYSTEM
      # ----------------------
      # EXIT HYPRLAND: Terminate the session and return to display manager
      # Key: [SUPER] + [SHIFT] + [M]
      "$mainMod SHIFT, M, exit"
    ];
    bindm = [
      # WINDOW MOVE
      # ----------------------
      # MOUSE MOVE: Drag the window using the mouse
      # Key: [SUPER] + [SHIFT] + [Left Click]
      "$mainMod SHIFT, mouse:272, movewindow"

      # WINDOW RESIZE
      # ----------------------
      # MOUSE RESIZE: Resize the window using the mouse
      # Key: [SUPER] + [Right Click]
      "$mainMod SHIFT, mouse:273, resizewindow"
    ];
    extraConfig = ''
      # KEYBOARD RESIZE: Enter a dedicated resize mode to avoid holding modifier keys
      # Key: [SUPER] + [R] to enter -> [h/j/k/l] to resize -> [Esc] to exit
      bind = $mainMod, R, submap, resize
      submap = resize
      binde = , h, exec, ${hyprWindowResize}/bin/hypr-window-resize -40 0
      binde = , l, exec, ${hyprWindowResize}/bin/hypr-window-resize 40 0
      binde = , k, exec, ${hyprWindowResize}/bin/hypr-window-resize 0 -40
      binde = , j, exec, ${hyprWindowResize}/bin/hypr-window-resize 0 40
      bind = , escape, submap, reset
      submap = reset

      # TOGGLE FLOATING / TILING: Switch state between floating and tiling
      # Key: [SUPER] + [V]
      bind = $mainMod, V, togglefloating
      bind = $mainMod, V, resizeactive, exact 50% 50%
      bind = $mainMod, V, centerwindow
    '';
  };
}
