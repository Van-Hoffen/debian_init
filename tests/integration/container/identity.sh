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
DO_IDENTITY=yes

before_id="$(cat /etc/machine-id 2>/dev/null || true)"
before_key=""
if [[ -f /etc/ssh/ssh_host_ed25519_key ]]; then
    before_key="$(sha256sum /etc/ssh/ssh_host_ed25519_key | awk '{print $1}')"
fi

step_identity >/dev/null

after_id="$(cat /etc/machine-id 2>/dev/null || true)"
[[ "$after_id" =~ ^[0-9a-f]{32}$ ]] || fail "machine-id не похож на 32 hex: [$after_id]"
assert_ne "$before_id" "$after_id" "machine-id"

assert_file /etc/ssh/ssh_host_ed25519_key
after_key="$(sha256sum /etc/ssh/ssh_host_ed25519_key | awk '{print $1}')"
assert_ne "$before_key" "$after_key" "SSH host key"

finish
