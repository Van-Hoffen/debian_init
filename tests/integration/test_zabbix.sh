#!/usr/bin/env bash
# INT-008: zabbix-конфиг.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=lib/docker.sh
. "$TESTS_DIR/lib/docker.sh"

check_zabbix() {
    docker_ready || fail "Docker недоступен"
    run_debian13 bash /tests/integration/container/zabbix.sh
}

test_case "zabbix: Server/ServerActive/Hostname и отсутствие пакета" check_zabbix
finish
