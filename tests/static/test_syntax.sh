#!/usr/bin/env bash
# STAT-001: синтаксис всех bash-скриптов.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"

check_syntax() {
    local f
    while IFS= read -r -d '' f; do
        bash -n "$f" || fail "синтаксис: ${f#"$ROOT_DIR"/}"
    done < <(find "$ROOT_DIR" -type f -name '*.sh' -not -path '*/.git/*' -print0)
}

check_install_exec() {
    assert_exec "$ROOT_DIR/install.sh"
}

test_case "bash -n: все .sh" check_syntax
test_case "install.sh исполняемый" check_install_exec
finish
