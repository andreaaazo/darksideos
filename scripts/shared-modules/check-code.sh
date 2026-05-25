#!/usr/bin/env bash
set -euo pipefail

# Shared-modules static code checks.
# Scopes:
# - file: one static check or all file-level checks
# - module: module-level static checks
# - full: full shared-modules static stack
# - all: every shared-modules static check

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nix-build.sh
source "${SCRIPT_DIR}/../lib/nix-build.sh"

require_env SHARED_MODULES_CHECK_SCOPE "file, module, full, all"
require_env SHARED_MODULES_CHECK_TARGET "all, or a scope-specific target"
require_env SHARED_MODULES_CHECK_SHOW_NIX_LOGS "true, false"

scope="$SHARED_MODULES_CHECK_SCOPE"
target="$SHARED_MODULES_CHECK_TARGET"
show_nix_logs="$SHARED_MODULES_CHECK_SHOW_NIX_LOGS"
attr_set="checks.x86_64-linux"
output_pattern='\[PASS\]|\[FAIL\]|(warning|error):|Evaluated '

require_boolean SHARED_MODULES_CHECK_SHOW_NIX_LOGS "$show_nix_logs"

case "$scope" in
  file | module | full | all) ;;
  *)
    echo "Unsupported SHARED_MODULES_CHECK_SCOPE='${scope}'. Supported values: file, module, full, all." >&2
    exit 1
    ;;
esac

all_tests="$(nix_attr_names "$attr_set")"
file_tests="$(echo "$all_tests" | grep -E '^check-shared-modules-' || true)"
module_tests="$(echo "$all_tests" | grep -E '^check-module-shared-modules' || true)"
full_tests="$(echo "$all_tests" | grep -E '^check-stack-shared-modules$' || true)"

normalize_file_target() {
  local raw_target="$1"

  case "$raw_target" in
    check-*)
      printf '%s\n' "$raw_target"
      ;;
    *)
      printf 'check-shared-modules-%s\n' "$raw_target"
      ;;
  esac
}

normalize_module_target() {
  local raw_target="$1"

  case "$raw_target" in
    check-module-*)
      printf '%s\n' "$raw_target"
      ;;
    nixos-configurations)
      printf 'check-module-shared-modules-%s\n' "$raw_target"
      ;;
    *)
      printf 'check-module-shared-modules-%s\n' "$raw_target"
      ;;
  esac
}

case "$scope" in
  file)
    if [[ "$target" == "all" ]]; then
      selected_tests="$file_tests"
    else
      selected_tests="$(normalize_file_target "$target")"
      line_exists "$file_tests" "$selected_tests" || {
        echo "Unknown shared-modules file check target: ${target} (normalized: ${selected_tests})." >&2
        echo "Available targets:" >&2
        echo "$file_tests" >&2
        exit 1
      }
    fi
    ;;
  module)
    if [[ "$target" == "all" ]]; then
      selected_tests="$module_tests"
    else
      selected_tests="$(normalize_module_target "$target")"
      line_exists "$module_tests" "$selected_tests" || {
        echo "Unknown shared-modules module check target: ${target} (normalized: ${selected_tests})." >&2
        echo "Available targets:" >&2
        echo "$module_tests" >&2
        exit 1
      }
    fi
    ;;
  full)
    if [[ "$target" != "all" && "$target" != "shared-modules" && "$target" != "check-stack-shared-modules" ]]; then
      echo "SHARED_MODULES_CHECK_TARGET must be 'all', 'shared-modules', or 'check-stack-shared-modules' when SHARED_MODULES_CHECK_SCOPE=full." >&2
      exit 1
    fi
    if [[ "$target" == "check-stack-shared-modules" ]]; then
      selected_tests="$full_tests"
    else
      selected_tests="$(
        {
          echo "$file_tests"
          echo "$module_tests"
          echo "$full_tests"
        } | sort -u
      )"
    fi
    ;;
  all)
    if [[ "$target" != "all" ]]; then
      echo "SHARED_MODULES_CHECK_TARGET must be 'all' when SHARED_MODULES_CHECK_SCOPE=all." >&2
      exit 1
    fi
    selected_tests="$(
      {
        echo "$file_tests"
        echo "$module_tests"
        echo "$full_tests"
      } | sort -u
    )"
    ;;
esac

run_nix_builds "$attr_set" "$selected_tests" "$show_nix_logs" "$output_pattern"
