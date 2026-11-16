#!/usr/bin/env bash
set -euo pipefail
cd /src

help="$(./install.sh --help)"
[[ "$help" == *"Использование:"* ]]
[[ "$help" == *"--allow-remove"* ]]
[[ "$help" == *"--mode"* ]]
[[ "$help" == *"--extras"* ]]
[[ "$help" == *"--only"* ]]
[[ "$help" == *"--skip"* ]]

diff -u /tests/snapshots/steps.txt <(./install.sh --list-steps)

expect_fail() {
    local msg="$1"; shift
    local out
    if out="$("$@" 2>&1)"; then
        echo "ожидалась ошибка: $*"
        echo "$out"
        return 1
    fi
    if [[ "$out" != *"$msg"* ]]; then
        echo "нет сообщения [$msg] в выводе:"
        echo "$out"
        return 1
    fi
}

expect_fail "Неизвестный параметр" ./install.sh --bad-flag
expect_fail "требует значение" ./install.sh --hostname
expect_fail "требует значение" ./install.sh --mode
expect_fail "Неизвестный шаг" ./install.sh --only nope
expect_fail "Недопустимое имя" ./install.sh --hostname bad_name
expect_fail "Неизвестный режим" ./install.sh --mode nope

echo "CLI OK"
