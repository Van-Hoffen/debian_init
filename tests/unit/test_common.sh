#!/usr/bin/env bash
# UNIT-001..006: функции lib/common.sh с моками apt/dpkg.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=/dev/null
. "$ROOT_DIR/lib/common.sh"

DRY_RUN=false
ASSUME_YES=true
ALLOW_REMOVE=false
SYSTEMD_RUNNING=false
LOG_FILE=""

make_mocks() {
    local dir="$1"
    mkdir -p "$dir"
    cat > "$dir/apt-get" <<'MOCK'
#!/usr/bin/env bash
printf 'apt-get %s\n' "$*" >> "${APT_LOG:?}"
case " $* " in
    *" -s "*) for p in ${SIM_REMOVALS:-}; do printf 'Remv %s [1.0]\n' "$p"; done; exit 0 ;;
esac
for p in ${FAIL_PKGS:-}; do
    case " $* " in *" $p "*) exit 100 ;; esac
done
exit 0
MOCK
    cat > "$dir/apt-cache" <<'MOCK'
#!/usr/bin/env bash
pkg="${*: -1}"
case " ${MISSING_PKGS:-} " in
    *" $pkg "*) echo "  Candidate: (none)" ;;
    *) echo "  Candidate: 1.0" ;;
esac
MOCK
    cat > "$dir/dpkg-query" <<'MOCK'
#!/usr/bin/env bash
pkg="${*: -1}"
case " ${INSTALLED_PKGS:-} " in
    *" $pkg "*) echo "install ok installed" ;;
    *) echo "deinstall ok config-files" ;;
esac
MOCK
    cat > "$dir/dpkg" <<'MOCK'
#!/usr/bin/env bash
printf 'dpkg %s\n' "$*" >> "${APT_LOG:?}"
exit 0
MOCK
    chmod +x "$dir"/*
}

setup_mocks() {
    local tmp="$1"
    MOCK_DIR="$tmp/mock"
    make_mocks "$MOCK_DIR"
    APT_LOG="$tmp/apt.log"
    : > "$APT_LOG"
    PATH="$MOCK_DIR:$PATH"
    export APT_LOG PATH
    SIM_REMOVALS=""
    FAIL_PKGS=""
    MISSING_PKGS=""
    INSTALLED_PKGS=""
    export SIM_REMOVALS FAIL_PKGS MISSING_PKGS INSTALLED_PKGS
}

test_valid_hostname() {
    local h
    for h in srv-web01 a b1 a-b 1a a1; do
        valid_hostname "$h" || fail "должно быть допустимо: $h"
    done
    for h in '' '-a' 'a-' 'a_b' 'a.b' 'a b' 'a--' 'абв'; do
        if valid_hostname "$h"; then fail "должно быть недопустимо: [$h]"; fi
    done
    local long
    long="$(printf 'a%.0s' {1..64})"
    if valid_hostname "$long"; then fail "64 символа недопустимы"; fi
}

test_read_list() {
    local tmp got
    tmp="$(mktemp -d)"
    trap "rm -rf -- '$tmp'" EXIT
    printf '# comment\n\n  pkg1  \npkg2 # tail\n' > "$tmp/list"
    mapfile -t got < <(read_list "$tmp/list")
    assert_eq "pkg1 pkg2" "${got[*]}" "read_list"
}

test_sed_escape() {
    assert_contains "$(sed_escape_re 'a.b/c')" '\.' "escaped dot"
    assert_contains "$(sed_escape_re 'a.b/c')" '\/' "escaped slash"
    assert_eq 'a\/b\&c' "$(sed_escape_rep 'a/b&c')" "sed_escape_rep"
}

test_ensure_normal() {
    local tmp out
    tmp="$(mktemp -d)"
    trap "rm -rf -- '$tmp'" EXIT
    setup_mocks "$tmp"
    out="$(ensure_pkgs mutt mc 2>&1)"
    assert_contains "$out" "Установка: mutt mc"
    grep -q 'install --no-remove mutt mc' "$APT_LOG" || fail "нет вызова с --no-remove"
}

test_ensure_removals_fallback() {
    local tmp out
    tmp="$(mktemp -d)"
    trap "rm -rf -- '$tmp'" EXIT
    setup_mocks "$tmp"
    SIM_REMOVALS="beget-agent"; export SIM_REMOVALS
    FAIL_PKGS="build-essential"; export FAIL_PKGS
    out="$(ensure_pkgs build-essential mutt 2>&1)"
    assert_contains "$out" "потребовала бы удалить: beget-agent"
    assert_contains "$out" "повторяю по одному"
    assert_contains "$out" "Не удалось установить: build-essential"
    grep -q 'dpkg --configure -a' "$APT_LOG" || fail "нет dpkg --configure -a"
    grep -q 'install --no-remove mutt' "$APT_LOG" || fail "mutt не ставился поштучно"
}

test_ensure_missing_and_allow() {
    local tmp out
    tmp="$(mktemp -d)"
    trap "rm -rf -- '$tmp'" EXIT
    setup_mocks "$tmp"
    MISSING_PKGS="nope"; export MISSING_PKGS
    out="$(ensure_pkgs mutt nope 2>&1)"
    assert_contains "$out" "отсутствуют в репозиториях и пропущены: nope"
    grep -q 'install --no-remove mutt' "$APT_LOG" || fail "mutt не ставился"

    : > "$APT_LOG"
    ALLOW_REMOVE=true
    ensure_pkgs mutt >/dev/null 2>&1
    if grep -q -- '--no-remove' "$APT_LOG"; then fail "--no-remove при ALLOW_REMOVE=true"; fi
    ALLOW_REMOVE=false
}

test_run() {
    local out
    DRY_RUN=true
    out="$(run false 2>&1)"
    assert_contains "$out" "[DRY]"
    DRY_RUN=false
    if run false >/dev/null 2>&1; then fail "run false должен вернуть ошибку"; fi
}

test_apt_removals() {
    local tmp removals
    tmp="$(mktemp -d)"
    trap "rm -rf -- '$tmp'" EXIT
    setup_mocks "$tmp"
    SIM_REMOVALS="a b"; export SIM_REMOVALS
    mapfile -t removals < <(apt_removals pkg)
    assert_eq "a b" "${removals[*]}" "apt_removals"
}

test_list_human_users() {
    local tmp out
    tmp="$(mktemp -d)"
    trap "rm -rf -- '$tmp'" EXIT
    mkdir -p "$tmp/alice" "$tmp/bob"
    # shellcheck disable=SC2317
    getent() {
        printf 'alice:x:1000:1000::%s:/bin/bash\n' "$tmp/alice"
        printf 'bob:x:1001:1001::%s:/usr/sbin/nologin\n' "$tmp/bob"
        printf 'root:x:0:0::/root:/bin/bash\n'
    }
    # shellcheck disable=SC2317
    uid_min() { echo 1000; }
    out="$(list_human_users)"
    assert_contains "$out" "alice:"
    assert_not_contains "$out" "bob:"
    assert_not_contains "$out" "root:"
}

test_case "valid_hostname" test_valid_hostname
test_case "read_list" test_read_list
test_case "sed_escape_*" test_sed_escape
test_case "ensure_pkgs: обычная установка" test_ensure_normal
test_case "ensure_pkgs: удаление и fallback" test_ensure_removals_fallback
test_case "ensure_pkgs: отсутствующий пакет и --allow-remove" test_ensure_missing_and_allow
test_case "run: dry-run и ошибки" test_run
test_case "apt_removals" test_apt_removals
test_case "list_human_users: фильтрация" test_list_human_users
finish
