# shellcheck shell=bash
# Помощники для Docker-тестов. Требуют ROOT_DIR и TESTS_DIR из tests/run.sh.

docker_ready() {
    command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1
}

require_docker() {
    docker_ready || {
        echo "Docker недоступен: интеграционные тесты требуют docker info" >&2
        return 1
    }
}

ensure_image() {
    local image="$1"
    docker image inspect "$image" >/dev/null 2>&1 || docker pull -q "$image" >/dev/null
}

ensure_systemd_image() {
    local tag="debian-init-test:systemd"
    if ! docker image inspect "$tag" >/dev/null 2>&1; then
        docker build -q -t "$tag" "$TESTS_DIR/docker/systemd" >/dev/null
    fi
}

run_debian13() {
    docker run --rm \
        -v "$ROOT_DIR:/src:ro" \
        -v "$TESTS_DIR:/tests:ro" \
        -w /src \
        debian:13 "$@"
}

run_debian13_privileged() {
    docker run --rm --privileged \
        -v "$ROOT_DIR:/src:ro" \
        -v "$TESTS_DIR:/tests:ro" \
        -w /src \
        debian:13 "$@"
}

run_debian13_offline() {
    docker run --rm --network none \
        -v "$ROOT_DIR:/src:ro" \
        -v "$TESTS_DIR:/tests:ro" \
        -w /src \
        debian:13 "$@"
}

run_systemd_image() {
    ensure_systemd_image
    docker run --rm \
        -v "$ROOT_DIR:/src:ro" \
        -v "$TESTS_DIR:/tests:ro" \
        -w /src \
        debian-init-test:systemd "$@"
}
