set shell := ["bash", "-euo", "pipefail", "-c"]

docker_image := "darksideos-checks:latest"

# Persistent Nix store cache shared across runs.
# Docker copies the image's /nix into this named volume on first mount, then
# every `nix build` inside the container reuses it instead of re-fetching
# nixpkgs and re-building derivations each time.
# The volume name is keyed on the Docker build inputs (Dockerfile + flake.lock),
# so changing tools or pinned versions transparently rotates to a fresh,
# consistent cache rather than serving stale store paths.
nix_cache_volume := "darksideos-nix-" + sha256(sha256_file("Dockerfile") + sha256_file("flake.lock"))

docker-build:
    docker build -f Dockerfile -t {{ docker_image }} .

# Remove every DarksideOS Nix cache volume (current and rotated-out ones).
clean-cache:
    docker volume ls -q --filter name=darksideos-nix- | xargs -r docker volume rm
    @echo "Removed DarksideOS Nix cache volumes."

shared-modules-check-code scope target show_nix_logs: docker-build
    docker run --rm \
      -e SHARED_MODULES_CHECK_SCOPE="{{ scope }}" \
      -e SHARED_MODULES_CHECK_TARGET="{{ target }}" \
      -e SHARED_MODULES_CHECK_SHOW_NIX_LOGS="{{ show_nix_logs }}" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/shared-modules/check-code.sh

shared-modules-check-eval scope target show_nix_logs: docker-build
    docker run --rm \
      -e SHARED_MODULES_EVAL_SCOPE="{{ scope }}" \
      -e SHARED_MODULES_EVAL_TARGET="{{ target }}" \
      -e SHARED_MODULES_EVAL_SHOW_NIX_LOGS="{{ show_nix_logs }}" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/shared-modules/check-eval.sh

shared-modules-check-unit show_nix_logs: docker-build
    docker run --rm \
      -e SHARED_MODULES_UNIT_SHOW_NIX_LOGS="{{ show_nix_logs }}" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/shared-modules/check-unit.sh

shared-modules-check-vm scope target show_nixos_logs: docker-build
    kvm_args=(); \
    if [[ -e /dev/kvm ]]; then kvm_args+=(--device /dev/kvm); fi; \
    docker run --rm \
      -e SHARED_MODULES_VM_SCOPE="{{ scope }}" \
      -e SHARED_MODULES_VM_TARGET="{{ target }}" \
      -e SHARED_MODULES_VM_SHOW_NIXOS_LOGS="{{ show_nixos_logs }}" \
      "${kvm_args[@]}" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/shared-modules/check-vm.sh

shared-modules-format-code: docker-build
    docker run --rm \
      -e HOST_UID="$(id -u)" \
      -e HOST_GID="$(id -g)" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/shared-modules/format-code.sh

shared-modules-lint-code show_nix_logs: docker-build
    docker run --rm \
      -e SHARED_MODULES_LINT_SHOW_NIX_LOGS="{{ show_nix_logs }}" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/shared-modules/lint-code.sh

shared-modules-dead-code show_nix_logs: docker-build
    docker run --rm \
      -e SHARED_MODULES_DEAD_CODE_SHOW_NIX_LOGS="{{ show_nix_logs }}" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/shared-modules/dead-code.sh

iso-check-static show_nixos_logs: docker-build
    docker run --rm \
      -e ISO_STATIC_SHOW_NIX_LOGS="{{ show_nixos_logs }}" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/iso/check-static.sh

iso-check-unit show_nixos_logs: docker-build
    docker run --rm \
      -e ISO_UNIT_SHOW_NIX_LOGS="{{ show_nixos_logs }}" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/iso/check-unit.sh

iso-check-integration show_nixos_logs: docker-build
    docker run --rm \
      -e ISO_INTEGRATION_SHOW_NIX_LOGS="{{ show_nixos_logs }}" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/iso/check-integration.sh

iso-check-eval show_nixos_logs: docker-build
    docker run --rm \
      -e ISO_EVAL_SHOW_NIX_LOGS="{{ show_nixos_logs }}" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/iso/check-eval.sh

iso-check-vm show_nixos_logs: docker-build
    kvm_args=(); \
    if [[ -e /dev/kvm ]]; then kvm_args+=(--device /dev/kvm); fi; \
    docker run --rm \
      -e ISO_VM_SHOW_NIXOS_LOGS="{{ show_nixos_logs }}" \
      "${kvm_args[@]}" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/iso/check-vm.sh

iso-check-cve show_nixos_logs: docker-build
    docker run --rm \
      --network host \
      -e ISO_CVE_SHOW_NIX_LOGS="{{ show_nixos_logs }}" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/iso/check-cve.sh

iso-check-reproducibility: docker-build
    docker run --rm \
      --network host \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/iso/check-reproducibility.sh

iso-check-all show_nixos_logs: docker-build
    kvm_args=(); \
    if [[ -e /dev/kvm ]]; then kvm_args+=(--device /dev/kvm); fi; \
    docker run --rm \
      -e ISO_ALL_SHOW_NIXOS_LOGS="{{ show_nixos_logs }}" \
      "${kvm_args[@]}" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/iso/check-all.sh

iso-format-code: docker-build
    docker run --rm \
      -e HOST_UID="$(id -u)" \
      -e HOST_GID="$(id -g)" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/iso/format-code.sh

iso-build: docker-build
    docker run --rm \
      -e HOST_UID="$(id -u)" \
      -e HOST_GID="$(id -g)" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/iso/iso-build.sh

iso-cleanup: docker-build
    docker run --rm \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/iso/iso-cleanup.sh

check-budget show_nix_logs: docker-build
    docker run --rm \
      -e REPO_BUDGET_SHOW_NIX_LOGS="{{ show_nix_logs }}" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/repo/check-budget.sh

update-lock: docker-build
    docker run --rm \
      -e HOST_UID="$(id -u)" \
      -e HOST_GID="$(id -g)" \
      -v {{ nix_cache_volume }}:/nix \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/repo/update-lock.sh
