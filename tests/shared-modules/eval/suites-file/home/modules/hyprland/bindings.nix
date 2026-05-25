# Eval tests for shared-modules/home/modules/hyprland/bindings.nix.
# Covers the keybinding contract that drives day-to-day window management.
{
  pkgs,
  testLib,
}: let
  config = testLib.getConfig {
    extraModules = [testLib.hmModule];
    modules = [
      ../../../../../../../shared-modules/home/home.nix
      {
        nixpkgs.config.allowUnfree = true;
        users.users.andrea = {
          isNormalUser = true;
          home = "/home/andrea";
        };
      }
    ];
  };

  hyprland = config.home-manager.users.andrea.wayland.windowManager.hyprland;
  bindList = hyprland.settings.bind;
  bindmList = hyprland.settings.bindm;
  extraConfig = hyprland.extraConfig;

  expectedBindEntries = [
    "$mainMod, h, movefocus, l"
    "$mainMod, l, movefocus, r"
    "$mainMod, k, movefocus, u"
    "$mainMod, j, movefocus, d"
    "$mainMod, Tab, cyclenext"
    "$mainMod, F, fullscreen"
    "$mainMod, P, pin"
    "$mainMod, Q, killactive"
    "$mainMod SHIFT, M, exit"
  ];

  expectedWorkspaceBindings = builtins.concatMap (workspace: [
    "$mainMod, ${workspace}, workspace, ${workspace}"
    "$mainMod SHIFT, ${workspace}, movetoworkspace, ${workspace}"
  ]) ["1" "2" "3" "4" "5" "6" "7" "8" "9"];

  expectedMouseBindings = [
    "$mainMod SHIFT, mouse:272, movewindow"
    "$mainMod SHIFT, mouse:273, resizewindow"
  ];

  bindAssertions = builtins.map (entry:
    testLib.assertContains {
      id = "home-hyprland-bindings-${builtins.hashString "sha256" entry}";
      name = "Hyprland bind list contains '${entry}'";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "settings"
        "bind"
      ];
      element = entry;
      severity = "high";
      rationale = "Core window-management shortcut must remain in the declarative bindings contract.";
    }) (expectedBindEntries ++ expectedWorkspaceBindings);

  mouseAssertions = builtins.map (entry:
    testLib.assertContains {
      id = "home-hyprland-bindm-${builtins.hashString "sha256" entry}";
      name = "Hyprland bindm list contains '${entry}'";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "settings"
        "bindm"
      ];
      element = entry;
      severity = "high";
      rationale = "Pointer-driven window manipulation binding must remain declarative.";
    }) expectedMouseBindings;

  staticAssertions = [
    (testLib.assertEqual {
      id = "home-hyprland-bindings-mainmod";
      name = "Hyprland mainMod is SUPER";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "settings"
        "$mainMod"
      ];
      expected = "SUPER";
      severity = "critical";
      rationale = "All shortcut chords depend on a stable $mainMod = SUPER baseline.";
    })

    (testLib.mkResult {
      id = "home-hyprland-bindings-count";
      name = "Hyprland bind list has expected minimum size";
      passed = (builtins.length bindList) >= (builtins.length (expectedBindEntries ++ expectedWorkspaceBindings));
      expected = ">= ${toString (builtins.length (expectedBindEntries ++ expectedWorkspaceBindings))} entries";
      actual = builtins.length bindList;
      severity = "medium";
      rationale = "Bind contract should not silently shrink under refactors.";
    })

    (testLib.mkResult {
      id = "home-hyprland-bindings-bindm-count";
      name = "Hyprland bindm list has expected minimum size";
      passed = (builtins.length bindmList) >= (builtins.length expectedMouseBindings);
      expected = ">= ${toString (builtins.length expectedMouseBindings)} entries";
      actual = builtins.length bindmList;
      severity = "medium";
      rationale = "Pointer bind contract should not silently shrink under refactors.";
    })

    (testLib.assertAnyContainsAllStringified {
      id = "home-hyprland-bindings-move-wrapper-left";
      name = "hypr-window-move wrapper is bound for leftward movement";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "settings"
        "bind"
      ];
      substrings = [
        "$mainMod SHIFT, H"
        "/nix/store/"
        "/bin/hypr-window-move l"
      ];
      severity = "high";
      rationale = "Wrapper script must be referenced by deterministic nix-store path, not by relative name.";
    })

    (testLib.assertAnyContainsAllStringified {
      id = "home-hyprland-bindings-move-wrapper-right";
      name = "hypr-window-move wrapper is bound for rightward movement";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "settings"
        "bind"
      ];
      substrings = [
        "$mainMod SHIFT, L"
        "/nix/store/"
        "/bin/hypr-window-move r"
      ];
      severity = "high";
      rationale = "Wrapper script must be referenced by deterministic nix-store path, not by relative name.";
    })

    (testLib.assertAnyContainsAllStringified {
      id = "home-hyprland-bindings-move-wrapper-up";
      name = "hypr-window-move wrapper is bound for upward movement";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "settings"
        "bind"
      ];
      substrings = [
        "$mainMod SHIFT, K"
        "/nix/store/"
        "/bin/hypr-window-move u"
      ];
      severity = "high";
      rationale = "Wrapper script must be referenced by deterministic nix-store path, not by relative name.";
    })

    (testLib.assertAnyContainsAllStringified {
      id = "home-hyprland-bindings-move-wrapper-down";
      name = "hypr-window-move wrapper is bound for downward movement";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "settings"
        "bind"
      ];
      substrings = [
        "$mainMod SHIFT, J"
        "/nix/store/"
        "/bin/hypr-window-move d"
      ];
      severity = "high";
      rationale = "Wrapper script must be referenced by deterministic nix-store path, not by relative name.";
    })

    (testLib.assertAnyContainsAllStringified {
      id = "home-hyprland-bindings-move-wrapper-center";
      name = "hypr-window-move wrapper is bound for centering";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "settings"
        "bind"
      ];
      substrings = [
        "$mainMod SHIFT, C"
        "/nix/store/"
        "/bin/hypr-window-move c"
      ];
      severity = "high";
      rationale = "Wrapper script must be referenced by deterministic nix-store path, not by relative name.";
    })

    (testLib.assertStringContains {
      id = "home-hyprland-bindings-resize-submap";
      name = "Hyprland resize submap is declared in extraConfig";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "extraConfig"
      ];
      substring = "submap = resize";
      severity = "high";
      rationale = "Resize submap is the only way to enter the dedicated resize workflow.";
    })

    (testLib.assertStringContains {
      id = "home-hyprland-bindings-resize-submap-reset";
      name = "Hyprland resize submap exits cleanly via reset";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "extraConfig"
      ];
      substring = "submap = reset";
      severity = "high";
      rationale = "Submap reset prevents the user from getting stuck inside resize mode.";
    })

    (testLib.assertStringContains {
      id = "home-hyprland-bindings-toggle-floating";
      name = "togglefloating is bound to $mainMod, V";
      inherit config;
      path = [
        "home-manager"
        "users"
        "andrea"
        "wayland"
        "windowManager"
        "hyprland"
        "extraConfig"
      ];
      substring = "bind = $mainMod, V, togglefloating";
      severity = "high";
      rationale = "Tile/float toggle must remain the documented $mainMod+V shortcut.";
    })

    (testLib.mkResult {
      id = "home-hyprland-bindings-resize-wrapper-presence";
      name = "hypr-window-resize wrapper appears in extraConfig";
      passed =
        pkgs.lib.hasInfix "/nix/store/" extraConfig
        && pkgs.lib.hasInfix "/bin/hypr-window-resize " extraConfig;
      expected = "extraConfig containing a nix-store /bin/hypr-window-resize reference";
      actual = extraConfig;
      severity = "high";
      rationale = "Resize submap relies on the wrapper as a deterministic store binary.";
    })
  ];

  assertions = bindAssertions ++ mouseAssertions ++ staticAssertions;
in
  pkgs.runCommand "eval-home-modules-hyprland-bindings" {} (
    testLib.mkCheckScript {
      name = "home/modules/hyprland/bindings";
      assertionResults = assertions;
    }
  )
