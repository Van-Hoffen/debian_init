#!/usr/bin/env bash
# INT-004: users.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=lib/docker.sh
. "$TESTS_DIR/lib/docker.sh"

check_users() {
    docker_ready || fail "Docker недоступен"
    run_debian13 bash /tests/integration/container/users.sh
}

test_case "users: фильтрация, владелец, идемпотентность" check_users
finish
