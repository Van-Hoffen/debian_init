#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
. /tests/lib/assert.sh
# shellcheck source=/dev/null
. /src/lib/common.sh
# shellcheck source=/dev/null
. /src/modules/10-base.sh

REPO_DIR=/src
DRY_RUN=false
BACKUP_DIR=/tmp/backups

# cdrom отключается, debian.sources создаётся
mkdir -p /etc/apt/sources.list.d
printf 'deb cdrom:[test] trixie main\n' > /etc/apt/sources.list
rm -f /etc/apt/sources.list.d/debian.sources
OS_ID=debian
OS_CODENAME=trixie
fix_apt_sources
grep -q '^# deb cdrom' /etc/apt/sources.list || fail "cdrom не отключён"
assert_file /etc/apt/sources.list.d/debian.sources
grep -q 'Suites: trixie' /etc/apt/sources.list.d/debian.sources || fail "неверные Suites"

# dry-run preflight: определение ОС/платформы и вызов apt-get update
DRY_RUN=true
PLATFORM=hw
out="$(step_preflight 2>&1)"
assert_contains "$out" "ОС: Debian"
assert_contains "$out" "Платформа: hw"
assert_contains "$out" "apt-get update"

finish
