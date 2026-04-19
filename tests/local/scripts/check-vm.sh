#!/usr/bin/env bash
set -euo pipefail

# VM scope:
# - full (default): run complete dump (file-level + module-level + full-stack)
# - module: run module dump(s). With VM_TARGET=<name>, run one module dump.
#           Without VM_TARGET, run every module dump (all module file-level tests + vm-module-*)
# - file: run file-level test(s). With VM_TARGET=<name>, run one file-level test.
#         Without VM_TARGET, run all file-level tests
scope="${VM_SCOPE:-full}"
target="${VM_TARGET:-}"

tests="$(nix eval 'path:.#vmTests.x86_64-linux' --apply 'builtins.attrNames' --json)"

case "$scope" in
  full)
    selected_tests="$(echo "$tests" | jq -r '.[]' | sort -u)"
    ;;
  file)
    if [[ -n "$target" ]]; then
      file_target="$target"
      if [[ "$file_target" != vm-* ]]; then
        file_target="vm-$file_target"
      fi

      selected_tests="$(echo "$tests" | jq -r --arg t "$file_target" '.[] | select(. == $t)' | sort -u)"
    else
      selected_tests="$(echo "$tests" | jq -r '.[] | select(startswith("vm-module-") | not) | select(startswith("vm-stack-") | not)' | sort -u)"
    fi
    ;;
  module)
    if [[ -n "$target" ]]; then
      module_name="$target"
      module_name="${module_name#module:}"
      module_name="${module_name#vm-module-}"

      selected_tests="$(
        echo "$tests" | jq -r --arg m "$module_name" '
          .[] |
          select(
            . == ("vm-" + $m) or
            startswith("vm-" + $m + "-") or
            . == ("vm-module-" + $m)
          )
        ' | sort -u
      )"
    else
      selected_tests="$(
        echo "$tests" | jq -r '
          . as $all
          | [ .[] | select(startswith("vm-module-")) | sub("^vm-module-"; "") ] as $mods
          | $all[] as $t
          | select(
              any($mods[]; . as $m | $t == ("vm-" + $m) or ($t | startswith("vm-" + $m + "-")) or $t == ("vm-module-" + $m))
            )
          | $t
        ' | sort -u
      )"
    fi
    ;;
  *)
    echo "Unsupported VM_SCOPE='$scope'. Supported values: full, module, file." >&2
    exit 1
    ;;
esac

if [[ -z "$selected_tests" ]]; then
  if [[ -n "$target" ]]; then
    echo "No VM tests selected for VM_SCOPE='$scope' with VM_TARGET='$target'." >&2
  else
    echo "No VM tests selected for VM_SCOPE='$scope'." >&2
  fi
  exit 1
fi

for test in $selected_tests; do
  echo "Running ${test}"
  nix build \
    --no-write-lock-file \
    --option system-features "benchmark big-parallel nixos-test kvm uid-range" \
    "path:.#vmTests.x86_64-linux.${test}" \
    --print-build-logs
done
