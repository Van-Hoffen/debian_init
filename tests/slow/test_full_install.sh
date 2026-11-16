#!/usr/bin/env bash
# SLOW-001: полный реальный прогон fresh с пакетами.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=lib/docker.sh
. "$TESTS_DIR/lib/docker.sh"

check_full() {
    docker_ready || fail "Docker недоступен"
    docker run --rm \
        -v "$ROOT_DIR:/src:ro" \
        -w /src \
        debian:13 bash -c '
            set -e
            ./install.sh --mode fresh -y
            test -f /root/.bashrc
            test -f /etc/skel/.tmux.conf
            test -f /etc/bash/.bash_aliases
            dpkg -s git >/dev/null
            test -x /usr/bin/git
            echo FULL-INSTALL-OK
        '
}

test_case "полный install.sh --mode fresh -y" check_full
finish
