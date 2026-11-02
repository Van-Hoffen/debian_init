# shellcheck shell=bash
# =============================================================================
# modules/40-optional.sh — необязательные компоненты.
# Шаги: zabbix, extras
#
# extras — логика бывшего debian_setup.sh, но:
#   * запускается только по запросу (--extras LIST или вопрос в интерактиве);
#   * работает от root, пользовательские части выполняются через runuser;
#   * не ломается на netinst (нет sudo/curl — ставятся заранее);
#   * не дописывает дубли при повторном запуске;
#   * не трогает ~/.bashrc (интеграция fzf пишется в ~/.bashrc.local).
#
# Компоненты: gitconfig, dirs, sshperms, fzf, python, node, docker, zsh
# =============================================================================

EXTRAS_ALL=(gitconfig dirs sshperms fzf python node docker zsh)
NVM_VERSION="v0.40.8"

# -----------------------------------------------------------------------------
# zabbix — минимальная настройка zabbix-agent2 (Server, ServerActive, Hostname)
# -----------------------------------------------------------------------------
step_zabbix() {
    log_step "zabbix-agent2"
    local conf=/etc/zabbix/zabbix_agent2.conf
    if ! pkg_installed zabbix-agent2 || [[ ! -f "$conf" ]]; then
        log_info "zabbix-agent2 не установлен — пропуск"
        return 0
    fi
    local server="$ZABBIX_SERVER"
    if [[ -z "$server" ]]; then
        if grep -qE '^Server=(127\.0\.0\.1|localhost)?$' "$conf" && \
           ask_yn "Указать адрес Zabbix-сервера для агента?" n; then
            server="$(ask_value "Адрес(а) Zabbix-сервера через запятую")"
        fi
    fi
    if [[ -z "$server" ]]; then
        log_info "Адрес сервера не задан — конфиг не изменён"
        return 0
    fi
    local host rep_s rep_h
    host="$(current_hostname)"
    rep_s="$(sed_escape_rep "$server")"
    rep_h="$(sed_escape_rep "$host")"
    backup_system_file "$conf"
    run sed -i -E \
        -e "s/^#?[[:space:]]*Server=.*/Server=${rep_s}/" \
        -e "s/^#?[[:space:]]*ServerActive=.*/ServerActive=${rep_s}/" \
        -e "s/^#?[[:space:]]*Hostname=.*/Hostname=${rep_h}/" \
        "$conf"
    log_info "Server=$server, Hostname=$host"
    if [[ "$SYSTEMD_RUNNING" == true ]]; then
        run systemctl enable zabbix-agent2.service
        run systemctl restart zabbix-agent2.service
    fi
}

# -----------------------------------------------------------------------------
# extras
# -----------------------------------------------------------------------------
step_extras() {
    log_step "Дополнительные компоненты"
    local list="$EXTRAS"
    if [[ -z "$list" ]]; then
        if is_interactive && ask_yn "Установить дополнительные компоненты (${EXTRAS_ALL[*]})?" n; then
            list="$(ask_value "Компоненты через запятую или all" "gitconfig,dirs,sshperms,fzf")"
        fi
    fi
    if [[ -z "$list" ]]; then
        log_info "Не запрошено"
        return 0
    fi
    [[ "$list" == all ]] && list="$(IFS=,; echo "${EXTRAS_ALL[*]}")"

    # Пользователь, для которого ставятся пользовательские части
    local user="$EXTRAS_USER" home
    if [[ -z "$user" ]]; then
        user="${SUDO_USER:-}"
        [[ "$user" == root ]] && user=""
    fi
    if [[ -z "$user" ]]; then
        local users=()
        mapfile -t users < <(list_human_users | cut -d: -f1)
        if (( ${#users[@]} == 1 )); then
            user="${users[0]}"
        else
            user="$(ask_value "Для какого пользователя (${users[*]:-нет обычных}; root — для root)" "${users[0]:-root}")"
        fi
    fi
    id -u "$user" >/dev/null 2>&1 || die "Пользователь не найден: $user"
    home="$(getent passwd "$user" | cut -d: -f6)"
    log_info "Пользователь: $user ($home)"

    local c
    IFS=, read -r -a comps <<< "$list"
    for c in "${comps[@]}"; do
        c="${c//[[:space:]]/}"
        [[ -z "$c" ]] && continue
        if declare -F "extra_$c" >/dev/null; then
            log_info "--- $c"
            "extra_$c" "$user" "$home" || add_warning "Компонент $c завершился с ошибкой"
        else
            add_warning "Неизвестный компонент: $c (доступны: ${EXTRAS_ALL[*]})"
        fi
    done
}

# Выполнить команду от имени пользователя с его HOME
as_user() {
    local user="$1"; shift
    local home
    home="$(getent passwd "$user" | cut -d: -f6)"
    run runuser -u "$user" -- env HOME="$home" USER="$user" "$@"
}

# Добавить блок в ~/.bashrc.local пользователя один раз (по маркеру)
append_local_once() {
    local user="$1" home="$2" marker="$3" text="$4" f="$2/.bashrc.local"
    if [[ -f "$f" ]] && grep -qF "$marker" "$f"; then
        log_info "  $f уже содержит: $marker"
        return 0
    fi
    as_user "$user" sh -c 'printf "\n%s\n%s\n" "$1" "$2" >> "$3"' _ "$marker" "$text" "$f"
}

extra_gitconfig() {
    local user="$1" name="$GIT_NAME" email="$GIT_EMAIL"
    ensure_pkgs git
    [[ -z "$name" ]]  && name="$(runuser -u "$user" -- git config --global user.name 2>/dev/null || true)"
    [[ -z "$name" ]]  && name="$(ask_value "Git: имя (user.name)")"
    [[ -z "$email" ]] && email="$(runuser -u "$user" -- git config --global user.email 2>/dev/null || true)"
    [[ -z "$email" ]] && email="$(ask_value "Git: email (user.email)")"
    [[ -n "$name" ]]  && as_user "$user" git config --global user.name "$name"
    [[ -n "$email" ]] && as_user "$user" git config --global user.email "$email"
    as_user "$user" git config --global core.editor vim
    as_user "$user" git config --global merge.tool vimdiff
    as_user "$user" git config --global push.default simple
    as_user "$user" git config --global init.defaultBranch main
}

extra_dirs() {
    local user="$1" home="$2"
    as_user "$user" mkdir -p "$home/Projects" "$home/Documents" "$home/Downloads" "$home/Temp" "$home/Scripts"
}

extra_sshperms() {
    local user="$1" home="$2"
    [[ -d "$home/.ssh" ]] || { log_info "  $home/.ssh нет — пропуск"; return 0; }
    as_user "$user" chmod 700 "$home/.ssh"
    as_user "$user" find "$home/.ssh" -maxdepth 1 -type f \( -name 'id_*' ! -name '*.pub' -o -name authorized_keys \) -exec chmod 600 {} +
    as_user "$user" find "$home/.ssh" -maxdepth 1 -type f -name '*.pub' -exec chmod 644 {} +
}

extra_fzf() {
    local user="$1" home="$2"
    ensure_pkgs fzf
    # fzf >= 0.48 умеет `fzf --bash`; для Debian 12 — файл из пакета
    append_local_once "$user" "$home" "# fzf: Ctrl-R / Ctrl-T / Alt-C (debian_init)" \
'if command -v fzf >/dev/null; then
    eval "$(fzf --bash 2>/dev/null)" 2>/dev/null \
        || { [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash; }
fi'
}

extra_python() {
    # В Debian 12+ pip в системный Python запрещён (PEP 668) — используем pipx/venv
    ensure_pkgs python3 python3-pip python3-venv python3-dev pipx
    as_user "$1" pipx ensurepath || true
}

extra_node() {
    local user="$1" home="$2"
    ensure_pkgs curl ca-certificates
    if [[ -s "$home/.nvm/nvm.sh" ]]; then
        log_info "  nvm уже установлен"
    else
        # PROFILE=/dev/null — не дописывать ~/.bashrc; подключение — в ~/.bashrc.local
        as_user "$user" bash -c "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | PROFILE=/dev/null bash"
    fi
    append_local_once "$user" "$home" "# nvm (debian_init)" \
'export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"'
    as_user "$user" bash -c '. "$HOME/.nvm/nvm.sh" && nvm install --lts && nvm alias default "lts/*"'
}

extra_docker() {
    local user="$1"
    if command -v docker >/dev/null; then
        log_info "  Docker уже установлен"
    else
        ensure_pkgs ca-certificates curl
        local codename
        codename="$(. /etc/os-release && echo "${VERSION_CODENAME:-}")"
        [[ -n "$codename" ]] || die "Не удалось определить codename Debian"
        run install -d -m 0755 /etc/apt/keyrings
        run curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
        run chmod a+r /etc/apt/keyrings/docker.asc
        local tmp
        tmp="$(mktemp)"
        cat > "$tmp" <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $codename
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
        install_system_file "$tmp" /etc/apt/sources.list.d/docker.sources 0644
        rm -f "$tmp"
        apt_get update
        apt_get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
    if [[ "$user" != root ]]; then
        run usermod -aG docker "$user"
        log_info "  $user добавлен в группу docker (нужен повторный вход)"
    fi
}

extra_zsh() {
    local user="$1" home="$2"
    ensure_pkgs zsh git curl ca-certificates
    local custom="$home/.oh-my-zsh/custom"
    if [[ ! -d "$home/.oh-my-zsh" ]]; then
        as_user "$user" bash -c 'curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | RUNZSH=no CHSH=no sh -s -- --unattended'
    fi
    [[ -d "$custom/themes/powerlevel10k" ]] || \
        as_user "$user" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$custom/themes/powerlevel10k"
    [[ -d "$custom/plugins/zsh-syntax-highlighting" ]] || \
        as_user "$user" git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom/plugins/zsh-syntax-highlighting"
    [[ -d "$custom/plugins/zsh-autosuggestions" ]] || \
        as_user "$user" git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$custom/plugins/zsh-autosuggestions"
    if [[ -f "$home/.zshrc" ]]; then
        as_user "$user" sed -i \
            -e 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' \
            -e 's|^plugins=(.*)|plugins=(git zsh-syntax-highlighting zsh-autosuggestions)|' \
            "$home/.zshrc"
    fi
    # Всё окружение проекта (.bashrc, welcome, автозапуск tmux) — для bash,
    # поэтому оболочка по умолчанию меняется только с явного согласия.
    if ask_yn "Сделать zsh оболочкой по умолчанию для $user? (bash-окружение проекта перестанет загружаться)" n; then
        run chsh -s "$(command -v zsh)" "$user"
    fi
}
