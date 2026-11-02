# shellcheck shell=bash
# =============================================================================
# modules/10-base.sh — подготовка системы, обновление, установка пакетов.
# Шаги: preflight, upgrade, packages
# =============================================================================

# -----------------------------------------------------------------------------
# preflight — проверка ОС и источников apt, apt-get update.
# Выполняется всегда (не отключается через --skip).
# -----------------------------------------------------------------------------
step_preflight() {
    log_step "Проверка системы"

    # --- ОС ------------------------------------------------------------------
    [[ -r /etc/os-release ]] || die "Нет /etc/os-release — система не поддерживается."
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_VERSION="${VERSION_ID:-0}"
    OS_CODENAME="${VERSION_CODENAME:-}"
    log_info "ОС: ${PRETTY_NAME:-$OS_ID} (codename: ${OS_CODENAME:-?})"

    if [[ "$OS_ID" != debian ]]; then
        add_warning "Проект рассчитан на Debian, обнаружено: $OS_ID. Продолжаем на ваш риск."
    elif [[ "${OS_VERSION%%.*}" =~ ^[0-9]+$ ]] && (( ${OS_VERSION%%.*} < 12 )); then
        add_warning "Debian $OS_VERSION старее 12 — проверялось только на 12 и 13."
    fi

    # --- Платформа: железо / VM / контейнер -----------------------------------
    if [[ "$PLATFORM" == auto ]]; then
        VIRT="$(systemd-detect-virt 2>/dev/null || true)"
        VIRT="${VIRT:-none}"
    else
        VIRT="$PLATFORM"
    fi
    log_info "Платформа: $VIRT"

    # --- Источники apt ------------------------------------------------------
    fix_apt_sources

    # --- apt-get update -----------------------------------------------------
    log_info "Обновление списка пакетов (apt-get update)..."
    if ! apt_get update; then
        die "apt-get update завершился с ошибкой. Проверьте сеть и /etc/apt/sources.list*."
    fi
}

# После netinst без зеркала (или с DVD) в sources.list остаётся только
# строка 'deb cdrom:' — обновления и пакеты из сети недоступны.
fix_apt_sources() {
    local list=/etc/apt/sources.list
    local deb822=/etc/apt/sources.list.d/debian.sources

    if [[ -f "$list" ]] && grep -qE '^[[:space:]]*deb(-src)?[[:space:]]+cdrom:' "$list"; then
        log_info "Отключаю источник cdrom в $list"
        backup_system_file "$list"
        run sed -i -E 's/^([[:space:]]*deb(-src)?[[:space:]]+cdrom:)/# \1/' "$list"
    fi

    # Есть ли хоть один активный сетевой источник?
    local active=false f
    if grep -hqsE '^[[:space:]]*deb[[:space:]]' "$list" /etc/apt/sources.list.d/*.list 2>/dev/null; then
        active=true
    fi
    for f in /etc/apt/sources.list.d/*.sources; do
        [[ -f "$f" ]] || continue
        grep -qiE '^[[:space:]]*Enabled:[[:space:]]*no' "$f" && continue
        grep -qiE '^[[:space:]]*Types:' "$f" && active=true
    done

    if [[ "$active" == false ]]; then
        [[ "$OS_ID" == debian && -n "$OS_CODENAME" ]] \
            || die "Нет активных источников apt, а создать их автоматически можно только для Debian."
        log_warn "Активных источников apt нет — создаю $deb822 (deb.debian.org, $OS_CODENAME)"
        local tmp
        tmp="$(mktemp)"
        cat > "$tmp" <<EOF
# Создано debian_init: стандартные источники Debian $OS_CODENAME
Types: deb
URIs: http://deb.debian.org/debian
Suites: $OS_CODENAME $OS_CODENAME-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: $OS_CODENAME-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
        install_system_file "$tmp" "$deb822" 0644
        rm -f "$tmp"
    fi
}

# -----------------------------------------------------------------------------
# upgrade — полное обновление системы
# -----------------------------------------------------------------------------
step_upgrade() {
    log_step "Обновление системы"
    apt_get full-upgrade
    apt_get autoremove --purge
    [[ -f /var/run/reboot-required ]] && REBOOT_REQUIRED=true
    return 0
}

# -----------------------------------------------------------------------------
# packages — базовый список + список под платформу.
#   packages/base.list            — всегда
#   packages/hw.list              — физический сервер (VIRT=none / hw)
#   packages/vm-<virt>.list       — VM (kvm, microsoft, vmware, ...)
#   контейнеры (lxc, docker, ...) — только base
# Пакеты, которых нет в текущем релизе, пропускаются с предупреждением.
# -----------------------------------------------------------------------------
step_packages() {
    log_step "Установка пакетов"
    local lists=("$REPO_DIR/packages/base.list") extra=""
    case "$VIRT" in
        none|hw)    extra="hw" ;;
        vm)         extra="vm-kvm" ;;   # --platform vm: считаем KVM/Proxmox
        lxc*|docker|podman|systemd-nspawn|openvz|wsl|container*) extra="" ;;
        *)          extra="vm-$VIRT" ;;
    esac
    if [[ -n "$extra" ]]; then
        if [[ -f "$REPO_DIR/packages/$extra.list" ]]; then
            lists+=("$REPO_DIR/packages/$extra.list")
        else
            log_info "Списка packages/$extra.list нет — ставим только base"
        fi
    fi
    log_info "Списки: ${lists[*]#"$REPO_DIR"/}"

    local pkgs=() l
    for l in "${lists[@]}"; do
        mapfile -t -O "${#pkgs[@]}" pkgs < <(read_list "$l")
    done
    ensure_pkgs "${pkgs[@]}"
}
