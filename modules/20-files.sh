# shellcheck shell=bash
# =============================================================================
# modules/20-files.sh — раскладка файлов из репозитория по системе.
# Шаги: system-files, dotfiles, users
#
#   files/etc/bash/*   -> /etc/bash/*        (общие для всех: алиасы, welcome)
#   files/home/.bashrc -> /root, /etc/skel, (users) домашние каталоги
#   files/home/.tmux.conf -> то же
#
# Личные правки пользователей НЕ затираются без следа:
#   - ~/.bashrc.local, ~/.user_aliases, ~/.tmux.local.conf установщик не трогает,
#     а .bashrc / .tmux.conf их подключают — правьте их;
#   - если ~/.bashrc или ~/.tmux.conf отличаются от эталона, старая версия
#     сохраняется рядом как ~/.bashrc.~N~.
# =============================================================================

DOTFILES=(.bashrc .tmux.conf)

# -----------------------------------------------------------------------------
# system-files — /etc/bash
# -----------------------------------------------------------------------------
step_system_files() {
    log_step "Системные файлы: /etc/bash"
    local src_dir="$REPO_DIR/files/etc/bash" f name
    run install -d -m 0755 -o root -g root /etc/bash
    for f in "$src_dir"/.[!.]* "$src_dir"/*; do
        [[ -f "$f" ]] || continue
        name="$(basename "$f")"
        case "$name" in
            # Описание сервера заполняется вручную на каждой машине — не перезаписываем
            .server_info) install_system_file "$f" "/etc/bash/$name" 0644 keep ;;
            *)            install_system_file "$f" "/etc/bash/$name" 0644 ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# dotfiles — /root и /etc/skel (шаблон для новых пользователей)
# -----------------------------------------------------------------------------
step_dotfiles() {
    log_step "Dotfiles: /root и /etc/skel"
    local f
    for f in "${DOTFILES[@]}"; do
        install_user_file root "$REPO_DIR/files/home/$f" "/root/$f"
        # Бэкап из /etc/skel уходит в $BACKUP_DIR, а не в /etc/skel,
        # иначе файлы .~N~ копировались бы каждому новому пользователю.
        install_system_file "$REPO_DIR/files/home/$f" "/etc/skel/$f" 0644
    done
}

# -----------------------------------------------------------------------------
# users — dotfiles всем существующим пользователям (UID >= UID_MIN)
# -----------------------------------------------------------------------------
step_users() {
    log_step "Dotfiles: существующие пользователи"
    local entries=() e user home f
    mapfile -t entries < <(list_human_users)
    if (( ${#entries[@]} == 0 )); then
        log_info "Обычных пользователей с домашним каталогом нет"
        return 0
    fi
    log_info "Найдено: $(printf '%s ' "${entries[@]%%:*}")"
    if ! ask_yn "Обновить ${DOTFILES[*]} у этих пользователей (старые версии сохранятся как .~N~)?" y; then
        log_info "Пропущено пользователем"
        return 0
    fi
    for e in "${entries[@]}"; do
        user="${e%%:*}"
        home="${e##*:}"
        log_info "Пользователь $user ($home)"
        for f in "${DOTFILES[@]}"; do
            install_user_file "$user" "$REPO_DIR/files/home/$f" "$home/$f" \
                || add_warning "Не удалось обновить $home/$f"
        done
    done
}
