#!/usr/bin/env bash
# INT-010: extras dirs/sshperms/append_local_once.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=lib/docker.sh
. "$TESTS_DIR/lib/docker.sh"

check_extras() {
    docker_ready || fail "Docker недоступен"
    run_debian13 bash /tests/integration/container/extras.sh
}

test_case "extras: dirs, sshperms, без дублей в .bashrc.local" check_extras
finish
