{
  # Hyprland input namespace for pointer and focus behavior.
  wayland.windowManager.hyprland.settings.input = {
    # FOCUS FOLLOWS MOUSE
    # Window under the cursor becomes focused automatically
    follow_mouse = 1;
    # POINTER SENSIVITY
    # Multiplies the cursor movement speed; higher values make the pointer move faster across the screen
    sensitivity = 1.5;
    # POINTER ACCELERATION PROFILE
    # Controls how pointer speed scales with motion; 'flat' means no acceleration, while 'adaptive' increases speed the faster you move the mouse
    accel_profile = "flat";
  };
}
