#!/usr/bin/env bash
# INT-013: режимы и выбор списков пакетов.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=lib/docker.sh
. "$TESTS_DIR/lib/docker.sh"

capture() {
    local out
    if ! out="$(run_debian13_offline "$@" 2>&1)"; then
        echo "$out"
        return 1
    fi
    printf '%s' "$out"
}

check_modes() {
    local out
    docker_ready || fail "Docker недоступен"

    out="$(capture ./install.sh --mode fresh -y --dry-run)"
    assert_contains "$out" "Режим: fresh"
    assert_contains "$out" "autoremove --purge"
    assert_not_contains "$out" "Dotfiles: существующие пользователи"

    out="$(capture ./install.sh --mode existing -y --dry-run)"
    assert_contains "$out" "Режим: existing"
    assert_contains "$out" "autoremove не выполняется"
    assert_contains "$out" "Dotfiles: существующие пользователи"

    out="$(capture ./install.sh --mode template -y --dry-run)"
    assert_contains "$out" "Режим: template"
    assert_contains "$out" "Уникальность клона"
    assert_not_contains "$out" "Dotfiles: существующие пользователи"

    out="$(capture ./install.sh --mode fresh -y --dry-run --platform vm)"
    assert_contains "$out" "packages/vm-kvm.list"

    out="$(capture ./install.sh --mode fresh -y --dry-run --platform microsoft)"
    assert_contains "$out" "packages/vm-microsoft.list"

    out="$(capture ./install.sh --only system-files --dry-run)"
    assert_not_contains "$out" "Обновление системы"

    out="$(capture ./install.sh --mode fresh -y --dry-run --skip upgrade)"
    assert_not_contains "$out" "full-upgrade"
}

test_case "режимы, --platform, --only и --skip" check_modes
finish
