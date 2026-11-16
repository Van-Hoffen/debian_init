#!/usr/bin/env bash
# INT-007: machine-id и SSH host keys.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=lib/docker.sh
. "$TESTS_DIR/lib/docker.sh"

check_identity() {
    docker_ready || fail "Docker недоступен"
    run_systemd_image bash /tests/integration/container/identity.sh
}

test_case "identity: machine-id и SSH host keys" check_identity
finish
