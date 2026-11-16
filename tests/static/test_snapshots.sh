#!/usr/bin/env bash
# STAT-003: контракт --help и --list-steps не меняется незаметно.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"

check_help() {
    local snapshot="$TESTS_DIR/snapshots/help.txt"
    assert_file "$snapshot"
    diff -u "$snapshot" <(cd "$ROOT_DIR" && ./install.sh --help) \
        || fail "вывод --help изменился; обновите снапшот: tests/run.sh --update-snapshots"
}

check_steps() {
    local snapshot="$TESTS_DIR/snapshots/steps.txt"
    assert_file "$snapshot"
    diff -u "$snapshot" <(cd "$ROOT_DIR" && ./install.sh --list-steps) \
        || fail "список шагов изменился; обновите снапшот: tests/run.sh --update-snapshots"
}

test_case "--help совпадает со снапшотом" check_help
test_case "--list-steps совпадает со снапшотом" check_steps
finish
