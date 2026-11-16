#!/usr/bin/env bash
# INT-001: preflight.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=lib/docker.sh
. "$TESTS_DIR/lib/docker.sh"

check_preflight() {
    docker_ready || fail "Docker недоступен"
    run_debian13 bash /tests/integration/container/preflight.sh
}

test_case "preflight: ОС, платформа, cdrom и debian.sources" check_preflight
finish
