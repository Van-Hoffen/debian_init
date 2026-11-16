#!/usr/bin/env bash
# CLI-003: второй экземпляр блокируется flock.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=lib/docker.sh
. "$TESTS_DIR/lib/docker.sh"

check_lock() {
    docker_ready || fail "Docker недоступен"
    run_debian13 bash /tests/cli/container/lock.sh
}

test_case "lock: второй экземпляр не запускается" check_lock
finish
