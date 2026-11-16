#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
. /src/lib/common.sh
# shellcheck source=/dev/null
. /src/modules/30-identity.sh

umount /etc/hostname 2>/dev/null || true
umount /etc/hosts 2>/dev/null || true
printf 'old-host\n' > /etc/hostname
printf '127.0.0.1 localhost\n' > /etc/hosts

REPO_DIR=/src
DRY_RUN=false
SYSTEMD_RUNNING=false
BACKUP_DIR=/tmp/backups
DO_HOSTNAME=yes
NEW_HOSTNAME=bad_name

# die должен завершить скрипт с ошибкой; если этого не произошло — тест падает.
step_hostname
echo "ожидалась ошибка для недопустимого hostname"
exit 1
