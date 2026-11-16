#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
. /tests/lib/assert.sh
# shellcheck source=/dev/null
. /src/lib/common.sh
# shellcheck source=/dev/null
. /src/modules/20-files.sh

REPO_DIR=/src
DRY_RUN=false
ASSUME_YES=true
SYSTEMD_RUNNING=false
BACKUP_DIR=/tmp/backups

# install_system_file: создание, идемпотентность, бэкап, keep, dry-run
src=/tmp/src-file
dst=/tmp/etc/example
printf 'one\n' > "$src"
install_system_file "$src" "$dst" 0640 >/dev/null
assert_file "$dst"
assert_eq one "$(cat "$dst")"
assert_mode "$dst" 640
assert_owner "$dst" root:root

out="$(install_system_file "$src" "$dst" 0640 2>&1)"
assert_contains "$out" "без изменений"

printf 'two\n' > "$src"
install_system_file "$src" "$dst" 0640 >/dev/null
assert_eq two "$(cat "$dst")"
assert_file "$BACKUP_DIR$dst"

printf 'keep\n' > "$dst"
install_system_file "$src" "$dst" 0640 keep >/dev/null
assert_eq keep "$(cat "$dst")"

DRY_RUN=true
install_system_file "$src" /tmp/new-file 0640 >/dev/null
assert_not_exists /tmp/new-file
DRY_RUN=false

# /etc/bash и .server_info keep
step_system_files >/dev/null
assert_file /etc/bash/.bash_aliases
assert_file /etc/bash/.bash_welcome
assert_file /etc/bash/.services_check
printf 'KEEP-ME\n' > /etc/bash/.server_info
step_system_files >/dev/null
assert_eq KEEP-ME "$(cat /etc/bash/.server_info)"

# /root и /etc/skel
step_dotfiles >/dev/null
assert_file /root/.bashrc
assert_file /root/.tmux.conf
assert_file /etc/skel/.bashrc
assert_file /etc/skel/.tmux.conf
assert_mode /root/.bashrc 644
assert_owner /root/.bashrc root:root

# Изменение пользовательского файла -> нумерованный бэкап
rm -f /root/.bashrc.~*~
printf '\n# local\n' >> /root/.bashrc
step_dotfiles >/dev/null
assert_file /root/.bashrc.~1~

# Повторный запуск без изменений не создаёт второй бэкап
step_dotfiles >/dev/null
assert_not_exists /root/.bashrc.~2~

# symlink не трогается
printf 'target\n' > /tmp/target
rm -f /root/.tmux.conf
ln -s /tmp/target /root/.tmux.conf
out="$(install_user_file root "$REPO_DIR/files/home/.tmux.conf" /root/.tmux.conf 2>&1)"
assert_contains "$out" "символическая ссылка"
assert_symlink /root/.tmux.conf
assert_eq target "$(cat /tmp/target)"

finish
