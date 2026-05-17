#!/usr/bin/env bash
set -euo pipefail

# Shared-modules NixOS eval tests.
# Scopes:
# - file: one eval test or all file-level eval tests
# - module: one shared module and its related file tests, or every module
# - full: full shared stack
# - all: every shared-modules eval test

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nix-build.sh
source "${SCRIPT_DIR}/../lib/nix-build.sh"

require_env SHARED_MODULES_EVAL_SCOPE "file, module, full, all"
require_env SHARED_MODULES_EVAL_TARGET "all, shared, shared-modules, eval-stack-shared, or a scope-specific target"
require_env SHARED_MODULES_EVAL_SHOW_NIX_LOGS "true, false"

scope="$SHARED_MODULES_EVAL_SCOPE"
target="$SHARED_MODULES_EVAL_TARGET"
show_nix_logs="$SHARED_MODULES_EVAL_SHOW_NIX_LOGS"
attr_set="evalTests.x86_64-linux"
output_pattern='\[PASS\]|\[FAIL\]|(Expected|Actual|Severity|Rationale):'

require_boolean SHARED_MODULES_EVAL_SHOW_NIX_LOGS "$show_nix_logs"

case "$scope" in
  file | module | full | all) ;;
  *)
    echo "Unsupported SHARED_MODULES_EVAL_SCOPE='${scope}'. Supported values: file, module, full, all." >&2
    exit 1
    ;;
esac

all_tests="$(nix_attr_names "$attr_set")"
shared_tests="$(
  echo "$all_tests" | grep -Ev '^(iso-check-eval($|-)|eval-iso-|eval-module-iso$|eval-stack-iso$)' || true
)"
file_tests="$(echo "$shared_tests" | grep -Ev '^eval-module-|^eval-stack-' || true)"
module_tests="$(echo "$shared_tests" | grep -E '^eval-module-' || true)"
full_tests="$(echo "$shared_tests" | grep -E '^eval-stack-shared$' || true)"
module_names="$(
  while IFS= read -r module_test; do
    [[ -n "$module_test" ]] || continue
    printf '%s\n' "${module_test#eval-module-}"
  done <<<"$module_tests" | sort -u
)"

normalize_file_target() {
  local raw_target="$1"

  case "$raw_target" in
    eval-*)
      printf '%s\n' "$raw_target"
      ;;
    *)
      printf 'eval-%s\n' "$raw_target"
      ;;
  esac
}

normalize_module_target() {
  local raw_target="$1"

  raw_target="${raw_target#module:}"
  raw_target="${raw_target#eval-module-}"
  printf '%s\n' "$raw_target"
}

select_module_related_tests() {
  local module_name="$1"

  echo "$shared_tests" | awk -v module="$module_name" '
    $0 == "eval-" module { print; next }
    index($0, "eval-" module "-") == 1 { print; next }
    $0 == "eval-module-" module { print; next }
  ' | sort -u
}

case "$scope" in
  file)
    if [[ "$target" == "all" ]]; then
      selected_tests="$file_tests"
    else
      selected_tests="$(normalize_file_target "$target")"
      line_exists "$file_tests" "$selected_tests" || {
        echo "Unknown shared-modules eval file target: ${target} (normalized: ${selected_tests})." >&2
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
        echo "Unknown shared-modules eval module target: ${target} (normalized: ${module_name})." >&2
        echo "Available targets:" >&2
        echo "$module_names" >&2
        exit 1
      }
      selected_tests="$(select_module_related_tests "$module_name")"
    fi
    ;;
  full)
    if [[ "$target" != "all" && "$target" != "shared" && "$target" != "shared-modules" && "$target" != "eval-stack-shared" ]]; then
      echo "SHARED_MODULES_EVAL_TARGET must be 'all', 'shared', 'shared-modules', or 'eval-stack-shared' when SHARED_MODULES_EVAL_SCOPE=full." >&2
      exit 1
    fi
    if [[ "$target" == "eval-stack-shared" ]]; then
      selected_tests="$full_tests"
    else
      selected_tests="$shared_tests"
    fi
    ;;
  all)
    if [[ "$target" != "all" ]]; then
      echo "SHARED_MODULES_EVAL_TARGET must be 'all' when SHARED_MODULES_EVAL_SCOPE=all." >&2
      exit 1
    fi
    selected_tests="$shared_tests"
    ;;
esac

run_nix_builds "$attr_set" "$selected_tests" "$show_nix_logs" "$output_pattern"
