#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
. /tests/lib/assert.sh
# shellcheck source=/dev/null
. /src/lib/common.sh
# shellcheck source=/dev/null
. /src/modules/10-base.sh

REPO_DIR=/src
DRY_RUN=true
BACKUP_DIR=/tmp/backups
REBOOT_REQUIRED=false

MODE=existing
out="$(step_upgrade 2>&1)"
assert_contains "$out" "full-upgrade"
assert_not_contains "$out" "autoremove --purge"

MODE=fresh
out="$(step_upgrade 2>&1)"
assert_contains "$out" "autoremove --purge"

touch /var/run/reboot-required
REBOOT_REQUIRED=false
step_upgrade >/dev/null 2>&1
assert_eq true "$REBOOT_REQUIRED" "флаг перезагрузки"
rm -f /var/run/reboot-required

finish
