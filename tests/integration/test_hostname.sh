#!/usr/bin/env bash
# INT-005/006: hostname.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=lib/docker.sh
. "$TESTS_DIR/lib/docker.sh"

check_hostname() {
    docker_ready || fail "Docker недоступен"
    run_debian13_privileged bash /tests/integration/container/hostname.sh
}

check_invalid() {
    local out
    if out="$(run_debian13_privileged bash /tests/integration/container/hostname-invalid.sh 2>&1)"; then
        fail "ожидалась ошибка для недопустимого hostname"
    fi
    assert_contains "$out" "Недопустимое имя"
}

test_case "hostname: /etc/hostname, 127.0.1.1, mailname, идемпотентность" check_hostname
test_case "hostname: недопустимое имя отклоняется" check_invalid
finish
