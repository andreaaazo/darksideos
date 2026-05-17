# shellcheck shell=bash
# Shared low-level helpers for dedicated test entrypoints.

require_value() {
  local name="$1"
  local value="$2"
  local supported="$3"

  if [[ -z "$value" ]]; then
    echo "${name} is required. Supported values: ${supported}." >&2
    exit 1
  fi
}

require_env() {
  local name="$1"
  local supported="$2"

  if [[ ! -v "$name" || -z "${!name}" ]]; then
    echo "${name} is required. Supported values: ${supported}." >&2
    exit 1
  fi
}

require_boolean() {
  local name="$1"
  local value="$2"

  case "$value" in
    true | false) ;;
    *)
      echo "Unsupported ${name}='${value}'. Supported values: true, false." >&2
      exit 1
      ;;
  esac
}

line_exists() {
  local lines="$1"
  local value="$2"

  echo "$lines" | grep -Fxq "$value"
}

require_selected_tests_exist() {
  local available_tests="$1"
  local selected_tests="$2"
  local target_label="$3"

  local test
  while IFS= read -r test; do
    [[ -n "$test" ]] || continue

    line_exists "$available_tests" "$test" || {
      echo "Unknown test selected for ${target_label}: ${test}." >&2
      echo "Available targets:" >&2
      echo "$available_tests" >&2
      exit 1
    }
  done <<<"$selected_tests"
}

nix_attr_names() {
  local attr_set="$1"

  nix eval "path:.#${attr_set}" --apply 'builtins.attrNames' --json \
    | jq -r '.[]' \
    | sort -u
}

run_nix_builds() {
  local attr_set="$1"
  local selected_tests="$2"
  local show_nix_logs="$3"
  local output_pattern="$4"

  if [[ -z "$selected_tests" ]]; then
    echo "No Nix attributes selected for ${attr_set}." >&2
    exit 1
  fi

  local extra_args=()
  if declare -p NIX_BUILD_EXTRA_ARGS >/dev/null 2>&1; then
    # shellcheck disable=SC2154
    extra_args=("${NIX_BUILD_EXTRA_ARGS[@]}")
  fi

  local test
  while IFS= read -r test; do
    [[ -n "$test" ]] || continue

    echo "Running ${test}"
    if [[ "$show_nix_logs" == "true" ]]; then
      nix build \
        --no-write-lock-file \
        "${extra_args[@]}" \
        "path:.#${attr_set}.${test}" \
        --print-build-logs
      continue
    fi

    local log_file
    log_file="$(mktemp)"
    if nix build \
      --no-write-lock-file \
      "${extra_args[@]}" \
      "path:.#${attr_set}.${test}" \
      --print-build-logs >"$log_file" 2>&1; then
      if grep -E "$output_pattern" "$log_file" >/dev/null 2>&1; then
        grep -E "$output_pattern" "$log_file"
      else
        echo "[PASS] ${test}: completed"
      fi
    else
      if grep -E "$output_pattern" "$log_file" >/dev/null 2>&1; then
        grep -E "$output_pattern" "$log_file" >&2
      else
        echo "[FAIL] ${test}: build failed without assertion markers." >&2
      fi
      rm -f "$log_file"
      exit 1
    fi
    rm -f "$log_file"
  done <<<"$selected_tests"
}
