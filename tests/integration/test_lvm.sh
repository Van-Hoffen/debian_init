#!/usr/bin/env bash
# INT-009: LVM без lvm2.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=lib/docker.sh
. "$TESTS_DIR/lib/docker.sh"

check_lvm() {
    docker_ready || fail "Docker недоступен"
    run_debian13 bash /tests/integration/container/lvm.sh
}

test_case "lvm: без lvm2 шаг пропускается" check_lvm
finish
