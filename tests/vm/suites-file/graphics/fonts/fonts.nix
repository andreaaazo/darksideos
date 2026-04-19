# VM test for shared-modules/graphics/fonts/fonts.nix
{vmLib}:
vmLib.mkVmTest {
  name = "graphics-fonts";
  nodeModules = [
    ../../../../../shared-modules/graphics/fonts/fonts.nix
  ];

  testScript = ''
    ${vmLib.assertions.common}

    assert_command(
        "vm-fonts-001",
        "fontconfig tools are available",
        "command -v fc-match >/dev/null && command -v fc-list >/dev/null",
        severity="high",
        rationale="Applications rely on fontconfig tooling and cache lookups",
    )
    assert_command(
        "vm-fonts-002",
        "fontconfig cache can be queried",
        "fc-list >/dev/null",
        severity="high",
        rationale="Font stack must be indexable at runtime",
    )
    assert_command(
        "vm-fonts-003",
        "JetBrains Mono Nerd font is installed",
        "fc-list | grep -F 'JetBrainsMono' >/dev/null",
        severity="high",
        rationale="Monospace baseline must include JetBrains Mono Nerd for terminal/editor consistency",
    )
    assert_command(
        "vm-fonts-004",
        "Inter font family is installed",
        "fc-list | grep -F 'Inter' >/dev/null",
        severity="high",
        rationale="Sans/serif fallback baseline depends on Inter availability",
    )
    assert_command(
        "vm-fonts-005",
        "Apple Color Emoji font is installed",
        "fc-list | grep -F 'AppleColorEmoji.ttf' >/dev/null",
        severity="high",
        rationale="Emoji rendering must resolve to Apple Color Emoji",
    )
    assert_command(
        "vm-fonts-006",
        "DIN Next custom fonts are installed",
        "test \"$(fc-list | grep -F 'DINNextW1G-' | wc -l)\" -ge 14",
        severity="medium",
        rationale="Shared custom DIN Next stack must be available system-wide",
    )
    assert_command(
        "vm-fonts-007",
        "monospace default resolves to JetBrains Mono Nerd",
        "fc-match monospace | grep -F 'JetBrainsMono' >/dev/null",
        severity="high",
        rationale="Monospace generic family must be pinned to the declared default",
    )
    assert_command(
        "vm-fonts-008",
        "sans-serif default resolves to Inter",
        "fc-match sans-serif | grep -F 'Inter' >/dev/null",
        severity="high",
        rationale="Sans-serif generic family must resolve to Inter baseline",
    )
    assert_command(
        "vm-fonts-009",
        "serif fallback resolves to Inter",
        "fc-match serif | grep -F 'Inter' >/dev/null",
        severity="medium",
        rationale="Serif generic family should follow declared fallback policy",
    )
    assert_command(
        "vm-fonts-010",
        "emoji default is configured as Apple Color Emoji",
        "grep -R 'Apple Color Emoji' /etc/fonts >/dev/null",
        severity="high",
        rationale="Fontconfig must include emoji default mapping for consistent rendering",
    )
    assert_command(
        "vm-fonts-011",
        "bitmap fonts are actively rejected in fontconfig policy",
        "grep -F '<patelt name=\"scalable\"><bool>false</bool></patelt>' /etc/fonts/conf.d/53-no-bitmaps.conf >/dev/null",
        severity="high",
        rationale="Legacy bitmap fonts should be blocked from selection",
    )
    assert_command(
        "vm-fonts-012",
        "per-user fontconfig override include is disabled",
        "! test -e /etc/fonts/conf.d/50-user.conf",
        severity="high",
        rationale="System policy should not include user-level fontconfig overrides",
    )
    assert_command(
        "vm-fonts-013",
        "no failed units after font stack activation",
        "test \"$(systemctl list-units --failed --plain --no-legend --all | wc -l)\" -eq 0",
        severity="high",
        rationale="Font configuration must not introduce service failures",
    )
  '';
}
