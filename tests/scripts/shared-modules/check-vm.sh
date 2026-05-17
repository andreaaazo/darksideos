#!/usr/bin/env bash
set -euo pipefail

# Shared-modules VM tests.
# Scopes:
# - file: one VM test or all file-level VM tests
# - module: one shared module and its related VM tests, or every module
# - full: full shared VM stack
# - all: every shared-modules VM test

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nix-build.sh
source "${SCRIPT_DIR}/../lib/nix-build.sh"

require_env SHARED_MODULES_VM_SCOPE "file, module, full, all"
require_env SHARED_MODULES_VM_TARGET "all, shared, shared-modules, vm-stack-shared, or a scope-specific target"
require_env SHARED_MODULES_VM_SHOW_NIXOS_LOGS "true, false"

scope="$SHARED_MODULES_VM_SCOPE"
target="$SHARED_MODULES_VM_TARGET"
show_nix_logs="$SHARED_MODULES_VM_SHOW_NIXOS_LOGS"
attr_set="vmTests.x86_64-linux"
output_pattern='\[PASS\]|\[FAIL\]|(Expected|Actual|Severity|Rationale):'
NIX_BUILD_EXTRA_ARGS=(--option system-features "benchmark big-parallel nixos-test kvm uid-range")

require_boolean SHARED_MODULES_VM_SHOW_NIXOS_LOGS "$show_nix_logs"

case "$scope" in
  file | module | full | all) ;;
  *)
    echo "Unsupported SHARED_MODULES_VM_SCOPE='${scope}'. Supported values: file, module, full, all." >&2
    exit 1
    ;;
esac

all_tests="$(nix_attr_names "$attr_set")"
shared_tests="$(
  echo "$all_tests" | grep -Ev '^(iso-check-vm($|-)|vm-iso-|vm-suite-iso-|vm-stack-iso$)' || true
)"
file_tests="$(echo "$shared_tests" | grep -Ev '^vm-module-|^vm-stack-' || true)"
module_tests="$(echo "$shared_tests" | grep -E '^vm-module-' || true)"
full_tests="$(echo "$shared_tests" | grep -E '^vm-stack-shared$' || true)"
module_names="$(
  while IFS= read -r module_test; do
    [[ -n "$module_test" ]] || continue
    printf '%s\n' "${module_test#vm-module-}"
  done <<<"$module_tests" | sort -u
)"

normalize_file_target() {
  local raw_target="$1"

  case "$raw_target" in
    vm-*)
      printf '%s\n' "$raw_target"
      ;;
    *)
      printf 'vm-%s\n' "$raw_target"
      ;;
  esac
}

normalize_module_target() {
  local raw_target="$1"

  raw_target="${raw_target#module:}"
  raw_target="${raw_target#vm-module-}"
  printf '%s\n' "$raw_target"
}

select_module_related_tests() {
  local module_name="$1"

  echo "$shared_tests" | awk -v module="$module_name" '
    $0 == "vm-" module { print; next }
    index($0, "vm-" module "-") == 1 { print; next }
    $0 == "vm-module-" module { print; next }
  ' | sort -u
}

case "$scope" in
  file)
    if [[ "$target" == "all" ]]; then
      selected_tests="$file_tests"
    else
      selected_tests="$(normalize_file_target "$target")"
      line_exists "$file_tests" "$selected_tests" || {
        echo "Unknown shared-modules VM file target: ${target} (normalized: ${selected_tests})." >&2
        echo "Available targets:" >&2
        echo "$file_tests" >&2
        exit 1
      }
    fi
    ;;
  module)
    if [[ "$target" == "all" ]]; then
      selected_tests="$(
        for module_name in $module_names; do
          select_module_related_tests "$module_name"
        done | sort -u
      )"
    else
      module_name="$(normalize_module_target "$target")"
      line_exists "$module_names" "$module_name" || {
        echo "Unknown shared-modules VM module target: ${target} (normalized: ${module_name})." >&2
        echo "Available targets:" >&2
        echo "$module_names" >&2
        exit 1
      }
      selected_tests="$(select_module_related_tests "$module_name")"
    fi
    ;;
  full)
    if [[ "$target" != "all" && "$target" != "shared" && "$target" != "shared-modules" && "$target" != "vm-stack-shared" ]]; then
      echo "SHARED_MODULES_VM_TARGET must be 'all', 'shared', 'shared-modules', or 'vm-stack-shared' when SHARED_MODULES_VM_SCOPE=full." >&2
      exit 1
    fi
    if [[ "$target" == "vm-stack-shared" ]]; then
      selected_tests="$full_tests"
    else
      selected_tests="$shared_tests"
    fi
    ;;
  all)
    if [[ "$target" != "all" ]]; then
      echo "SHARED_MODULES_VM_TARGET must be 'all' when SHARED_MODULES_VM_SCOPE=all." >&2
      exit 1
    fi
    selected_tests="$shared_tests"
    ;;
esac

run_nix_builds "$attr_set" "$selected_tests" "$show_nix_logs" "$output_pattern"
