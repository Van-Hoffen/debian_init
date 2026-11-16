#!/usr/bin/env bash
# INT-003/012: system-files, dotfiles, бэкапы, symlink, install_system_file.
set -euo pipefail
: "${ROOT_DIR:?}" "${TESTS_DIR:?}"
# shellcheck source=lib/assert.sh
. "$TESTS_DIR/lib/assert.sh"
# shellcheck source=lib/docker.sh
. "$TESTS_DIR/lib/docker.sh"

check_files() {
    docker_ready || fail "Docker недоступен"
    run_debian13 bash /tests/integration/container/files.sh
}

test_case "files: /etc/bash, /root, /etc/skel, бэкапы, keep, symlink" check_files
finish
