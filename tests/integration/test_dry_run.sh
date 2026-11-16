#!/usr/bin/env bash
# INT-011: полный dry-run.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=lib/docker.sh
. "$TESTS_DIR/lib/docker.sh"

check_dry_run() {
    local out
    docker_ready || fail "Docker недоступен"
    if ! out="$(run_debian13_offline ./install.sh --mode fresh --dry-run 2>&1)"; then
        echo "$out"
        fail "install.sh --dry-run завершился с ошибкой"
    fi
    assert_contains "$out" "Режим: fresh (DRY-RUN)"
    assert_contains "$out" "Это был DRY-RUN"
    run_debian13_offline bash -c \
        'test ! -e /etc/bash && test ! -e /var/backups/debian_init && test ! -e /var/log/debian_init.log'
}

test_case "dry-run: полный прогон fresh ничего не меняет" check_dry_run
finish
