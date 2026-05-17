# Verifies every sourced ISO shell module resolves to an existing file.
{
  pkgs,
  self,
}:
pkgs.runCommand "check-iso-script-imports" {
  nativeBuildInputs = [
    pkgs.coreutils
    pkgs.findutils
  ];
} ''
  source ${self}/tests/lib/shell/assertions.sh

  scripts_root="${self}/iso/scripts"
  [[ -d "$scripts_root" ]] || fail "ISO scripts directory exists" "directory iso/scripts" "missing directory" "critical" "Import validation cannot run without installer scripts."

  resolve_installer_path() {
    local variable_name="$1"
    local relative_source="$2"
    local base_path

    case "$variable_name" in
      DARKSIDEOS_INSTALLER_ROOT)
        base_path="$scripts_root"
        ;;
      DARKSIDEOS_INSTALLER_SHARED)
        base_path="$scripts_root/shared"
        ;;
      DARKSIDEOS_INSTALLER_DOMAIN)
        base_path="$scripts_root/domain"
        ;;
      DARKSIDEOS_INSTALLER_PRESENTATION)
        base_path="$scripts_root/presentation"
        ;;
      DARKSIDEOS_INSTALLER_APPLICATION)
        base_path="$scripts_root/application"
        ;;
      DARKSIDEOS_INSTALLER_DTOS)
        base_path="$scripts_root/application/dtos"
        ;;
      DARKSIDEOS_INSTALLER_SERVICES)
        base_path="$scripts_root/application/services"
        ;;
      DARKSIDEOS_INSTALLER_USE_CASES)
        base_path="$scripts_root/application/use-cases"
        ;;
      DARKSIDEOS_INSTALLER_INFRASTRUCTURE)
        base_path="$scripts_root/infrastructure"
        ;;
      DARKSIDEOS_INSTALLER_REPOSITORIES)
        base_path="$scripts_root/infrastructure/repositories"
        ;;
      DARKSIDEOS_INSTALLER_SYSTEM)
        base_path="$scripts_root/infrastructure/system"
        ;;
      DARKSIDEOS_INSTALLER_GENERATORS)
        base_path="$scripts_root/infrastructure/generators"
        ;;
      *)
        fail "Installer import variable is known: $variable_name" "known DARKSIDEOS_INSTALLER_* variable" "unknown variable" "high" "Imports must stay explicit so the script graph remains understandable."
        ;;
    esac

    printf '%s/%s\n' "$base_path" "$relative_source"
  }

  import_count=0

  while IFS= read -r -d "" script; do
    line_number=0
    while IFS= read -r source_line || [[ -n "$source_line" ]]; do
      line_number=$((line_number + 1))
      [[ "$source_line" =~ ^[[:space:]]*source[[:space:]] ]] || continue

      relative_script="''${script#${self}/}"
      if [[ "$source_line" =~ source[[:space:]]+\"[$][{]([A-Z_]+)[}]/([^\"]+)\" ]]; then
        variable_name="''${BASH_REMATCH[1]}"
        relative_source="''${BASH_REMATCH[2]}"
        target_path="$(resolve_installer_path "$variable_name" "$relative_source")"

        if [[ ! -f "$target_path" ]]; then
          fail "Import exists: $relative_script:$line_number" "existing file for $variable_name/$relative_source" "missing file" "critical" "Every sourced script must resolve before the installer starts."
        fi

        import_count=$((import_count + 1))
        pass "Import exists: $relative_script:$line_number -> ''${target_path#${self}/}" "source target exists" "source target exists" "critical" "Every sourced script must resolve before the installer starts."
        continue
      fi

      fail "Source expression is explicit: $relative_script:$line_number" 'source "$DARKSIDEOS_INSTALLER_*/file.sh"' "$source_line" "high" "Source expressions must remain explicit for static import resolution."
    done <"$script"
  done < <(find "$scripts_root" -type f -name '*.sh' -print0 | sort -z)

  [[ "$import_count" -gt 0 ]] || fail "ISO script imports exist" "at least one source import" "no imports found" "critical" "The installer should be composed from explicit modules."

  touch $out
''
