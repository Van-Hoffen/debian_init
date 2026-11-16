#!/usr/bin/env bash
# Запуск тестов debian_init.
#
#   tests/run.sh                    static + unit + cli + integration
#   tests/run.sh --tier unit        один уровень
#   tests/run.sh --tier all         включая slow
#   tests/run.sh --list             список тестов
#   tests/run.sh --filter files     по подстроке в пути
#   tests/run.sh --update-snapshots обновить снапшоты --help/--list-steps
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_DIR="$ROOT_DIR/tests"
export ROOT_DIR TESTS_DIR

TIERS=(static unit cli integration)
FILTER=""
LIST=0
UPDATE=0

usage() {
    cat <<EOF
Использование: tests/run.sh [--tier static|unit|cli|integration|slow|all] [--filter TEXT] [--list] [--update-snapshots]

По умолчанию: static unit cli integration.
slow требует Docker и сеть; vm пока не реализован.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tier)
            [[ $# -ge 2 ]] || { echo "--tier требует значение" >&2; exit 1; }
            case "$2" in
                fast) TIERS=(static unit cli integration) ;;
                all)  TIERS=(static unit cli integration slow) ;;
                static|unit|cli|integration|slow) TIERS=("$2") ;;
                vm)   echo "vm-тир пока не реализован: см. docs/test-plan.md (VM-001..VM-004)" >&2; exit 1 ;;
                *)    echo "Неизвестный tier: $2" >&2; exit 1 ;;
            esac
            shift
            ;;
        --filter) [[ $# -ge 2 ]] || { echo "--filter требует значение" >&2; exit 1; }; FILTER="$2"; shift ;;
        --list) LIST=1 ;;
        --update-snapshots) UPDATE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Неизвестный параметр: $1" >&2; usage >&2; exit 1 ;;
    esac
    shift
done

test_files_for() {
    local tier="$1"
    [[ -d "$TESTS_DIR/$tier" ]] || return 0
    find "$TESTS_DIR/$tier" -maxdepth 1 -type f -name 'test_*.sh' | sort
}

if (( UPDATE )); then
    mkdir -p "$TESTS_DIR/snapshots"
    ( cd "$ROOT_DIR" && ./install.sh --help > "$TESTS_DIR/snapshots/help.txt" )
    ( cd "$ROOT_DIR" && ./install.sh --list-steps > "$TESTS_DIR/snapshots/steps.txt" )
    echo "Снапшоты обновлены: tests/snapshots/"
    exit 0
fi

if (( LIST )); then
    for tier in "${TIERS[@]}"; do
        while IFS= read -r f; do
            printf '%-12s %s\n' "$tier" "${f#"$ROOT_DIR"/}"
        done < <(test_files_for "$tier")
    done
    exit 0
fi

# Docker нужен для cli/integration/slow.
for tier in "${TIERS[@]}"; do
    case "$tier" in
        cli|integration|slow)
            if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
                echo "Docker недоступен, а tier '$tier' без него не работает" >&2
                exit 1
            fi
            ;;
    esac
done

TOTAL=0
FAILED=0
for tier in "${TIERS[@]}"; do
    while IFS= read -r f; do
        [[ -n "$FILTER" && "$f" != *"$FILTER"* ]] && continue
        TOTAL=$(( TOTAL + 1 ))
        printf '\n### %s\n' "${f#"$ROOT_DIR"/}"
        if bash "$f"; then
            :
        else
            FAILED=$(( FAILED + 1 ))
        fi
    done < <(test_files_for "$tier")
done

echo
echo "Итого: $TOTAL тестовых файлов, провалено: $FAILED"
(( FAILED == 0 )) || exit 1
