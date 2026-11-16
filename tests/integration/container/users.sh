#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
. /tests/lib/assert.sh
# shellcheck source=/dev/null
. /src/lib/common.sh
# shellcheck source=/dev/null
. /src/modules/20-files.sh

useradd -m -s /bin/bash alice
useradd -m -s /usr/sbin/nologin bob
rm -f /home/bob/.bashrc /home/bob/.tmux.conf

REPO_DIR=/src
DRY_RUN=false
ASSUME_YES=true
SYSTEMD_RUNNING=false
BACKUP_DIR=/tmp/backups

users="$(list_human_users)"
assert_contains "$users" "alice:"
assert_not_contains "$users" "bob:"

step_users >/dev/null
assert_file /home/alice/.bashrc
assert_file /home/alice/.tmux.conf
assert_owner /home/alice/.bashrc alice:alice
assert_not_exists /home/bob/.bashrc

printf '\n# local\n' >> /home/alice/.bashrc
step_users >/dev/null
assert_file /home/alice/.bashrc.~1~
assert_owner /home/alice/.bashrc alice:alice

finish
