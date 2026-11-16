#!/usr/bin/env bash
set -euo pipefail
cd /src

flock /run/debian_init.lock -c 'sleep 2' &
pid=$!
sleep 0.3

if ./install.sh --mode fresh --dry-run >/tmp/lock.out 2>&1; then
    echo "ожидалась ошибка блокировки, но install.sh запустился"
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    exit 1
fi

grep -q 'уже выполняется' /tmp/lock.out

wait "$pid"
echo "LOCK OK"
