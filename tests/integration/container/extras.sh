#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
. /tests/lib/assert.sh
# shellcheck source=/dev/null
. /src/lib/common.sh
# shellcheck source=/dev/null
. /src/modules/40-optional.sh

useradd -m -s /bin/bash alice
mkdir -p /home/alice/.ssh
printf 'private\n' > /home/alice/.ssh/id_ed25519
printf 'public\n' > /home/alice/.ssh/id_ed25519.pub
printf 'ssh-ed25519 AAAA test\n' > /home/alice/.ssh/authorized_keys
chown -R alice:alice /home/alice/.ssh

REPO_DIR=/src
DRY_RUN=false
ASSUME_YES=true
SYSTEMD_RUNNING=false
BACKUP_DIR=/tmp/backups

extra_dirs alice /home/alice >/dev/null
assert_dir /home/alice/Projects
assert_dir /home/alice/Documents
assert_dir /home/alice/Downloads
assert_dir /home/alice/Temp
assert_dir /home/alice/Scripts
assert_owner /home/alice/Projects alice:alice

extra_sshperms alice /home/alice >/dev/null
assert_mode /home/alice/.ssh 700
assert_mode /home/alice/.ssh/id_ed25519 600
assert_mode /home/alice/.ssh/id_ed25519.pub 644
assert_mode /home/alice/.ssh/authorized_keys 600

append_local_once alice /home/alice "# test-marker" "line" >/dev/null
append_local_once alice /home/alice "# test-marker" "line" >/dev/null
assert_eq 1 "$(grep -c '# test-marker' /home/alice/.bashrc.local)" "маркер в .bashrc.local"
assert_owner /home/alice/.bashrc.local alice:alice

finish
