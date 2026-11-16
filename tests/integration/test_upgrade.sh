#!/usr/bin/env bash
# INT-002: upgrade.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=lib/docker.sh
. "$TESTS_DIR/lib/docker.sh"

check_upgrade() {
    docker_ready || fail "Docker недоступен"
    run_debian13 bash /tests/integration/container/upgrade.sh
}

test_case "upgrade: existing без autoremove, fresh с autoremove, reboot" check_upgrade
finish
