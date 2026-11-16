#!/usr/bin/env bash
# STAT-002: ShellCheck с .shellcheckrc.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=lib/docker.sh
. "$TESTS_DIR/lib/docker.sh"

check_shellcheck() {
    docker_ready || fail "Docker недоступен: нужен для shellcheck"
    docker run --rm -v "$ROOT_DIR:/src:ro" -w /src koalaman/shellcheck:stable \
        -x install.sh lib/*.sh modules/*.sh
}

test_case "shellcheck: install.sh, lib, modules" check_shellcheck
finish
