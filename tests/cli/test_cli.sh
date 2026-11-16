#!/usr/bin/env bash
# CLI-001/002: контракт CLI в изолированном Debian 13.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=lib/docker.sh
. "$TESTS_DIR/lib/docker.sh"

check_cli() {
    docker_ready || fail "Docker недоступен"
    run_debian13 bash /tests/cli/container/cli.sh
}

test_case "CLI: --help/--list-steps и отклонение неверных аргументов" check_cli
finish
