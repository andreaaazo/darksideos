#!/usr/bin/env bash
set -euo pipefail

# Eval scope:
# - full: run complete dump (file-level + module-level + full-stack)
# - module: run module dump(s). With EVAL_TARGET=<name>, run one module dump.
#           Without EVAL_TARGET, run every module dump (all module file-level tests + eval-module-*)
# - file: run file-level test(s). With EVAL_TARGET=<name>, run one file-level test.
#         Without EVAL_TARGET, run all file-level tests
scope="${EVAL_SCOPE:-}"
target="${EVAL_TARGET:-}"
show_nixos_logs="${EVAL_SHOW_NIXOS_LOGS:-}"

if [[ -z "$scope" ]]; then
  echo "EVAL_SCOPE is required. Supported values: full, module, file." >&2
  echo "Example: EVAL_SCOPE=full EVAL_SHOW_NIXOS_LOGS=false just check-eval" >&2
  exit 1
fi

if [[ -z "$show_nixos_logs" ]]; then
  echo "EVAL_SHOW_NIXOS_LOGS is required. Supported values: true, false." >&2
  echo "Example: EVAL_SCOPE=full EVAL_SHOW_NIXOS_LOGS=false just check-eval" >&2
  exit 1
fi

case "$show_nixos_logs" in
  true | false) ;;
  *)
    echo "Unsupported EVAL_SHOW_NIXOS_LOGS='$show_nixos_logs'. Supported values: true, false." >&2
    exit 1
    ;;
esac

tests="$(nix eval 'path:.#evalTests.x86_64-linux' --apply 'builtins.attrNames' --json)"
file_tests="$(echo "$tests" | jq -r '.[] | select(startswith("eval-module-") | not) | select(startswith("eval-stack-") | not)' | sort -u)"
module_names="$(echo "$tests" | jq -r '.[] | select(startswith("eval-module-")) | sub("^eval-module-"; "")' | sort -u)"

case "$scope" in
  full)
    if [[ -n "$target" ]]; then
      echo "EVAL_TARGET is not supported with EVAL_SCOPE=full. Use EVAL_SCOPE=file|module for targeted runs." >&2
      exit 1
    fi
    selected_tests="$(echo "$tests" | jq -r '.[]' | sort -u)"
    ;;
  file)
    if [[ -n "$target" ]]; then
      file_target="$target"
      if [[ "$file_target" != eval-* ]]; then
        file_target="eval-$file_target"
      fi

      if ! echo "$file_tests" | grep -Fxq "$file_target"; then
        echo "Unknown eval file target: '$target' (normalized: '$file_target')." >&2
        echo "Available eval file targets:" >&2
        echo "$file_tests" >&2
        exit 1
      fi

      selected_tests="$file_target"
    else
      selected_tests="$file_tests"
    fi
    ;;
  module)
    if [[ -n "$target" ]]; then
      module_name="$target"
      module_name="${module_name#module:}"
      module_name="${module_name#eval-module-}"

      if ! echo "$module_names" | grep -Fxq "$module_name"; then
        echo "Unknown eval module target: '$target' (normalized: '$module_name')." >&2
        echo "Available eval module targets:" >&2
        echo "$module_names" >&2
        exit 1
      fi

      selected_tests="$(
        echo "$tests" | jq -r --arg m "$module_name" '
          .[] |
          select(
            . == ("eval-" + $m) or
            startswith("eval-" + $m + "-") or
            . == ("eval-module-" + $m)
          )
        ' | sort -u
      )"
    else
      selected_tests="$(
        echo "$tests" | jq -r '
          . as $all
          | [ .[] | select(startswith("eval-module-")) | sub("^eval-module-"; "") ] as $mods
          | $all[] as $t
          | select(
              any($mods[]; . as $m | $t == ("eval-" + $m) or ($t | startswith("eval-" + $m + "-")) or $t == ("eval-module-" + $m))
            )
          | $t
        ' | sort -u
      )"
    fi
    ;;
  *)
    echo "Unsupported EVAL_SCOPE='$scope'. Supported values: full, module, file." >&2
    echo "Examples: EVAL_SCOPE=full EVAL_SHOW_NIXOS_LOGS=false just check-eval | EVAL_SCOPE=file EVAL_TARGET=eval-core-nix EVAL_SHOW_NIXOS_LOGS=true just check-eval" >&2
    exit 1
    ;;
esac

if [[ -z "$selected_tests" ]]; then
  if [[ -n "$target" ]]; then
    echo "No eval tests selected for EVAL_SCOPE='$scope' with EVAL_TARGET='$target'." >&2
  else
    echo "No eval tests selected for EVAL_SCOPE='$scope'." >&2
  fi
  exit 1
fi

for test in $selected_tests; do
  echo "Running ${test}"
  if [[ "$show_nixos_logs" == "true" ]]; then
    nix build --no-write-lock-file "path:.#evalTests.x86_64-linux.${test}" --print-build-logs
  else
    log_file="$(mktemp)"
    if nix build --no-write-lock-file "path:.#evalTests.x86_64-linux.${test}" --print-build-logs >"$log_file" 2>&1; then
      if grep -E '\[PASS\]|\[FAIL\]|(Expected|Actual|Severity|Rationale):' "$log_file" >/dev/null 2>&1; then
        grep -E '\[PASS\]|\[FAIL\]|(Expected|Actual|Severity|Rationale):' "$log_file"
      else
        echo "[PASS] ${test}: completed"
      fi
    else
      if grep -E '\[PASS\]|\[FAIL\]|(Expected|Actual|Severity|Rationale):' "$log_file" >/dev/null 2>&1; then
        grep -E '\[PASS\]|\[FAIL\]|(Expected|Actual|Severity|Rationale):' "$log_file" >&2
      else
        echo "[FAIL] ${test}: build failed without assertion markers." >&2
      fi
      rm -f "$log_file"
      exit 1
    fi
    rm -f "$log_file"
  fi
done
