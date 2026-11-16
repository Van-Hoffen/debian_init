#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
. /tests/lib/assert.sh
# shellcheck source=/dev/null
. /src/lib/common.sh
# shellcheck source=/dev/null
. /src/modules/30-identity.sh

REPO_DIR=/src
DRY_RUN=false
SYSTEMD_RUNNING=false
BACKUP_DIR=/tmp/backups
DO_LVM=yes

if command -v lvs >/dev/null 2>&1; then
    echo "lvm2 установлен — тест INT-009 применим только без lvm2, пропуск"
    finish
fi

out="$(step_lvm 2>&1)"
assert_contains "$out" "lvm2 не установлен"

finish
