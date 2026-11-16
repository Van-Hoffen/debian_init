#!/usr/bin/env bash
# Подсказывает, какие уровни и тесты затронуты текущими изменениями.
# Не запускает тесты и ничего не меняет.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

changed="$(
    {
        git diff --name-only
        git diff --cached --name-only
        git ls-files --others --exclude-standard
    } | sort -u
)"

if [[ -z "$changed" ]]; then
    echo "Изменений нет."
    exit 0
fi

declare -A seen_tiers=()
declare -A seen_tests=()
tiers=()
tests=()

add_tier() {
    local t
    for t in "$@"; do
        [[ -n "${seen_tiers[$t]:-}" ]] && continue
        seen_tiers[$t]=1
        tiers+=("$t")
    done
}

add_test() {
    local t
    for t in "$@"; do
        [[ -f "$t" ]] || continue
        [[ -n "${seen_tests[$t]:-}" ]] && continue
        seen_tests[$t]=1
        tests+=("$t")
    done
}

while IFS= read -r f; do
    case "$f" in
        install.sh)
            add_tier static cli integration slow
            add_test tests/static/test_snapshots.sh tests/cli/test_cli.sh \
                tests/cli/test_lock.sh tests/integration/test_dry_run.sh \
                tests/integration/test_modes.sh tests/slow/test_full_install.sh
            ;;
        lib/common.sh)
            add_tier unit integration slow
            add_test tests/unit/test_common.sh tests/integration/test_dry_run.sh \
                tests/integration/test_files.sh tests/slow/test_full_install.sh
            ;;
        modules/10-base.sh)
            add_tier integration slow
            add_test tests/integration/test_preflight.sh tests/integration/test_upgrade.sh \
                tests/integration/test_dry_run.sh tests/integration/test_modes.sh \
                tests/slow/test_full_install.sh
            ;;
        modules/20-files.sh)
            add_tier integration slow
            add_test tests/integration/test_files.sh tests/integration/test_users.sh \
                tests/integration/test_extras.sh tests/slow/test_full_install.sh
            ;;
        modules/30-identity.sh)
            add_tier integration slow
            add_test tests/integration/test_hostname.sh tests/integration/test_identity.sh \
                tests/integration/test_lvm.sh tests/integration/test_modes.sh \
                tests/slow/test_full_install.sh
            ;;
        modules/40-optional.sh)
            add_tier integration slow
            add_test tests/integration/test_zabbix.sh tests/integration/test_extras.sh \
                tests/slow/test_full_install.sh
            ;;
        packages/*)
            add_tier integration slow
            add_test tests/integration/test_modes.sh tests/integration/test_dry_run.sh \
                tests/slow/test_full_install.sh
            ;;
        files/*)
            add_tier integration slow
            add_test tests/integration/test_files.sh tests/integration/test_users.sh \
                tests/slow/test_full_install.sh
            ;;
        tests/*)
            add_tier static unit cli integration
            if [[ "$(basename "$f")" == test_*.sh ]]; then
                add_test "$f"
            fi
            ;;
        *.md|docs/*|README.md)
            add_tier static
            add_test tests/static/test_docs_links.sh tests/static/test_snapshots.sh
            ;;
        *)
            add_tier static unit cli integration
            ;;
    esac
done <<< "$changed"

printf 'Изменённые файлы:\n'
printf '  %s\n' $changed
printf '\nУровни: %s\n' "${tiers[*]}"
printf 'Команда: tests/run.sh --tier %s\n' "$(IFS=,; echo "${tiers[*]}")"
if (( ${#tests[@]} )); then
    printf '\nЗатронутые тесты:\n'
    printf '  %s\n' "${tests[@]}"
fi
