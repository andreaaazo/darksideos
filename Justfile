set shell := ["bash", "-euo", "pipefail", "-c"]

docker_image := "darksideos-checks:latest"

docker-build:
    docker build -f Dockerfile -t {{ docker_image }} .

shared-modules-check-code scope target show_nix_logs: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e SHARED_MODULES_CHECK_SCOPE="{{ scope }}" \
      -e SHARED_MODULES_CHECK_TARGET="{{ target }}" \
      -e SHARED_MODULES_CHECK_SHOW_NIX_LOGS="{{ show_nix_logs }}" \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./tests/scripts/shared-modules/check-code.sh

shared-modules-check-eval scope target show_nix_logs: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e SHARED_MODULES_EVAL_SCOPE="{{ scope }}" \
      -e SHARED_MODULES_EVAL_TARGET="{{ target }}" \
      -e SHARED_MODULES_EVAL_SHOW_NIX_LOGS="{{ show_nix_logs }}" \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./tests/scripts/shared-modules/check-eval.sh

shared-modules-check-vm scope target show_nixos_logs: docker-build
    kvm_args=(); \
    if [[ -e /dev/kvm ]]; then kvm_args+=(--device /dev/kvm); fi; \
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e SHARED_MODULES_VM_SCOPE="{{ scope }}" \
      -e SHARED_MODULES_VM_TARGET="{{ target }}" \
      -e SHARED_MODULES_VM_SHOW_NIXOS_LOGS="{{ show_nixos_logs }}" \
      "${kvm_args[@]}" \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./tests/scripts/shared-modules/check-vm.sh

shared-modules-format-code: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e HOST_UID="$(id -u)" \
      -e HOST_GID="$(id -g)" \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./tests/scripts/shared-modules/format-code.sh

shared-modules-lint-code show_nix_logs: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e SHARED_MODULES_LINT_SHOW_NIX_LOGS="{{ show_nix_logs }}" \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./tests/scripts/shared-modules/lint-code.sh

shared-modules-dead-code show_nix_logs: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e SHARED_MODULES_DEAD_CODE_SHOW_NIX_LOGS="{{ show_nix_logs }}" \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./tests/scripts/shared-modules/dead-code.sh

iso-check-static show_nixos_logs: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e ISO_STATIC_SHOW_NIX_LOGS="{{ show_nixos_logs }}" \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./tests/scripts/iso/check-static.sh

iso-check-unit show_nixos_logs: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e ISO_UNIT_SHOW_NIX_LOGS="{{ show_nixos_logs }}" \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./tests/scripts/iso/check-unit.sh

iso-check-integration show_nixos_logs: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e ISO_INTEGRATION_SHOW_NIX_LOGS="{{ show_nixos_logs }}" \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./tests/scripts/iso/check-integration.sh

iso-check-eval show_nixos_logs: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e ISO_EVAL_SHOW_NIX_LOGS="{{ show_nixos_logs }}" \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./tests/scripts/iso/check-eval.sh

iso-check-vm show_nixos_logs: docker-build
    kvm_args=(); \
    if [[ -e /dev/kvm ]]; then kvm_args+=(--device /dev/kvm); fi; \
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e ISO_VM_SHOW_NIXOS_LOGS="{{ show_nixos_logs }}" \
      "${kvm_args[@]}" \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./tests/scripts/iso/check-vm.sh

iso-check-all show_nixos_logs: docker-build
    kvm_args=(); \
    if [[ -e /dev/kvm ]]; then kvm_args+=(--device /dev/kvm); fi; \
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e ISO_ALL_SHOW_NIXOS_LOGS="{{ show_nixos_logs }}" \
      "${kvm_args[@]}" \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./tests/scripts/iso/check-all.sh

iso-format-code: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e HOST_UID="$(id -u)" \
      -e HOST_GID="$(id -g)" \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./tests/scripts/iso/format-code.sh

iso-build: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e HOST_UID="$(id -u)" \
      -e HOST_GID="$(id -g)" \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/iso/iso-build.sh

iso-cleanup: docker-build
    docker run --rm \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./scripts/iso/iso-cleanup.sh

update-lock: docker-build
    docker run --rm \
      -e NIX_CONFIG='experimental-features = nix-command flakes' \
      -e HOST_UID="$(id -u)" \
      -e HOST_GID="$(id -g)" \
      -v "$PWD:/work" \
      -w /work \
      {{ docker_image }} \
      bash ./tests/scripts/update-lock.sh
