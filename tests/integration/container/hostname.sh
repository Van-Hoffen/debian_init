#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
. /tests/lib/assert.sh
# shellcheck source=/dev/null
. /src/lib/common.sh
# shellcheck source=/dev/null
. /src/modules/30-identity.sh

umount /etc/hostname 2>/dev/null || true
umount /etc/hosts 2>/dev/null || true

printf 'old-host\n' > /etc/hostname
printf '127.0.0.1 localhost\n127.0.1.1 old-host\n' > /etc/hosts
printf 'old-host\n' > /etc/mailname

REPO_DIR=/src
DRY_RUN=false
SYSTEMD_RUNNING=false
BACKUP_DIR=/tmp/backups
DO_HOSTNAME=yes
NEW_HOSTNAME=new-host

step_hostname >/dev/null
assert_eq new-host "$(cat /etc/hostname)"
assert_eq 1 "$(grep -c '^127\.0\.1\.1[[:space:]].*new-host' /etc/hosts)" "строка 127.0.1.1"
assert_eq new-host "$(cat /etc/mailname)"
assert_file "$BACKUP_DIR/etc/hostname"

out="$(step_hostname 2>&1)"
assert_contains "$out" "Имя уже new-host"

finish
