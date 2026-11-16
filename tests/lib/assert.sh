# shellcheck shell=bash
# Минимальный TAP-подобный harness без внешних зависимостей.

# Нужно, чтобы set -e работал внутри command substitution в test_case.
shopt -s inherit_errexit 2>/dev/null || true

TESTS_RUN=0
TESTS_FAILED=0

test_case() {
    local name="$1" fn="$2" out rc
    TESTS_RUN=$(( TESTS_RUN + 1 ))
    if out="$("$fn" 2>&1)"; then
        rc=0
    else
        rc=$?
    fi
    if (( rc == 0 )); then
        printf 'ok %d - %s\n' "$TESTS_RUN" "$name"
    else
        printf 'not ok %d - %s\n' "$TESTS_RUN" "$name"
        printf '%s\n' "$out" | sed 's/^/#   /'
        TESTS_FAILED=$(( TESTS_FAILED + 1 ))
    fi
}

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    return 1
}

assert_eq() {
    local expected="$1" actual="$2" msg="${3:-}"
    [[ "$expected" == "$actual" ]] \
        || fail "${msg:+$msg: }ожидалось [$expected], получено [$actual]"
}

assert_ne() {
    local unexpected="$1" actual="$2" msg="${3:-}"
    [[ "$unexpected" != "$actual" ]] \
        || fail "${msg:+$msg: }не ожидалось [$unexpected]"
}

assert_contains() {
    local haystack="$1" needle="$2" msg="${3:-}"
    [[ "$haystack" == *"$needle"* ]] \
        || fail "${msg:+$msg: }нет [$needle] в выводе: $haystack"
}

assert_not_contains() {
    local haystack="$1" needle="$2" msg="${3:-}"
    [[ "$haystack" != *"$needle"* ]] \
        || fail "${msg:+$msg: }не ожидалось [$needle] в выводе: $haystack"
}

assert_file() {
    [[ -f "$1" ]] || fail "нет файла: $1"
}

assert_not_exists() {
    [[ ! -e "$1" ]] || fail "не должно существовать: $1"
}

assert_dir() {
    [[ -d "$1" ]] || fail "нет каталога: $1"
}

assert_exec() {
    [[ -x "$1" ]] || fail "файл не исполняемый: $1"
}

assert_symlink() {
    [[ -L "$1" ]] || fail "не символическая ссылка: $1"
}

assert_mode() {
    local path="$1" expected="$2"
    local actual
    actual="$(stat -c %a "$path" 2>/dev/null || true)"
    assert_eq "$expected" "$actual" "права $path"
}

assert_owner() {
    local path="$1" expected="$2"
    local actual
    actual="$(stat -c %U:%G "$path" 2>/dev/null || true)"
    assert_eq "$expected" "$actual" "владелец $path"
}

finish() {
    echo
    if (( TESTS_FAILED > 0 )); then
        echo "not ok - $TESTS_FAILED из $TESTS_RUN провалено"
        exit 1
    fi
    echo "ok - все $TESTS_RUN тестов пройдены"
    exit 0
}
