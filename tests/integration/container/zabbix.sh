#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
. /tests/lib/assert.sh
# shellcheck source=/dev/null
. /src/lib/common.sh
# shellcheck source=/dev/null
. /src/modules/40-optional.sh

printf 'zabbix-host\n' > /etc/hostname
mkdir -p /etc/zabbix
cat > /etc/zabbix/zabbix_agent2.conf <<'EOF'
Server=127.0.0.1
ServerActive=127.0.0.1
Hostname=Zabbix server
EOF

REPO_DIR=/src
DRY_RUN=false
SYSTEMD_RUNNING=false
BACKUP_DIR=/tmp/backups
ZABBIX_SERVER=10.0.0.5

pkg_installed() { return 0; }
step_zabbix >/dev/null
grep -qx 'Server=10.0.0.5' /etc/zabbix/zabbix_agent2.conf || fail "Server не заменён"
grep -qx 'ServerActive=10.0.0.5' /etc/zabbix/zabbix_agent2.conf || fail "ServerActive не заменён"
grep -qx 'Hostname=zabbix-host' /etc/zabbix/zabbix_agent2.conf || fail "Hostname не заменён"
assert_file "$BACKUP_DIR/etc/zabbix/zabbix_agent2.conf"

pkg_installed() { return 1; }
out="$(step_zabbix 2>&1)"
assert_contains "$out" "не установлен"
grep -qx 'Server=10.0.0.5' /etc/zabbix/zabbix_agent2.conf || fail "конфиг изменён без пакета"

finish
