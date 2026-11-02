# shellcheck shell=bash
# =============================================================================
# modules/30-identity.sh — имя компьютера, уникальность клона, имя группы LVM.
# Шаги: hostname, identity, lvm
#
# Переменные (из install.sh):
#   NEW_HOSTNAME   — новое имя (--hostname) или пусто
#   DO_HOSTNAME    — yes | no | ask
#   DO_IDENTITY    — yes | no | ask
#   DO_LVM         — yes | no | ask
#   VG_NAME        — явное имя VG (--vg-name) или пусто => "<hostname>-vg"
# =============================================================================

# -----------------------------------------------------------------------------
# hostname
# -----------------------------------------------------------------------------
step_hostname() {
    log_step "Имя компьютера"
    local old new
    old="$(current_hostname)"
    log_info "Текущее имя: $old"

    new="$NEW_HOSTNAME"
    if [[ -z "$new" ]]; then
        case "$DO_HOSTNAME" in
            no)  log_info "Переименование не запрошено"; return 0 ;;
            ask) ask_yn "Переименовать компьютер?" n || { log_info "Оставляем $old"; return 0; } ;;
        esac
        while true; do
            new="$(ask_value "Новое имя компьютера")"
            [[ -z "$new" ]] && { log_info "Имя не введено — пропуск"; return 0; }
            valid_hostname "$new" && break
            log_warn "Недопустимое имя: латиница, цифры, дефис (не первым/последним), до 63 символов."
            is_interactive || return 1
        done
    fi
    valid_hostname "$new" || die "Недопустимое имя компьютера: '$new'"

    if [[ "$new" == "$old" ]]; then
        log_info "Имя уже $new — изменений нет"
        return 0
    fi

    log_info "Новое имя: $old -> $new"
    local f
    for f in /etc/hostname /etc/hosts /etc/mailname; do backup_system_file "$f"; done

    # /etc/hostname и текущее имя ядра
    if [[ "$SYSTEMD_RUNNING" == true ]] && command -v hostnamectl >/dev/null; then
        run hostnamectl set-hostname "$new"
    else
        if [[ "$DRY_RUN" == true ]]; then log_dry "echo $new > /etc/hostname"
        else echo "$new" > /etc/hostname; fi
    fi

    # /etc/hosts: правим только строку 127.0.1.1 и только целые слова
    # (old и old.domain), чтобы не задеть посторонние записи.
    local re_old rep_new
    re_old="$(sed_escape_ere "$old")"
    rep_new="$(sed_escape_rep "$new")"
    if grep -qE '^127\.0\.1\.1[[:space:]]' /etc/hosts 2>/dev/null; then
        if grep -qE "^127\.0\.1\.1[[:space:]].*[[:space:]]${re_old}(\.|[[:space:]]|\$)" /etc/hosts; then
            run sed -i -E "/^127\.0\.1\.1[[:space:]]/ s/(^|[[:space:]])${re_old}(\.|[[:space:]]|\$)/\1${rep_new}\2/g" /etc/hosts
        else
            run sed -i -E "s/^127\.0\.1\.1[[:space:]].*/127.0.1.1\t${rep_new}/" /etc/hosts
        fi
    else
        if [[ "$DRY_RUN" == true ]]; then log_dry "добавить '127.0.1.1 $new' в /etc/hosts"
        else printf '127.0.1.1\t%s\n' "$new" >> /etc/hosts; fi
    fi

    # /etc/mailname (если есть, содержит имя хоста или FQDN)
    if [[ -f /etc/mailname ]]; then
        run sed -i -E "s/^${re_old}(\.|\$)/${rep_new}\1/" /etc/mailname
    fi

    grep -E '^127\.0\.1\.1' /etc/hosts | sed 's/^/  hosts: /' || true
    REBOOT_REQUIRED=true
}

# -----------------------------------------------------------------------------
# identity — уникальность клона шаблона: новый machine-id и SSH host keys.
# Без этого все VM из одного шаблона имеют одинаковые ключи SSH и machine-id
# (одинаковые DHCP client-id в systemd-networkd, journal и т.п.).
# -----------------------------------------------------------------------------
step_identity() {
    log_step "Уникальность клона (machine-id, SSH host keys)"
    case "$DO_IDENTITY" in
        no)  log_info "Не запрошено"; return 0 ;;
        ask) ask_yn "Сгенерировать новые machine-id и SSH host keys (рекомендуется для клона)?" y \
                 || { log_info "Пропущено"; return 0; } ;;
    esac

    # machine-id
    backup_system_file /etc/machine-id
    run rm -f /etc/machine-id
    [[ -L /var/lib/dbus/machine-id ]] || run rm -f /var/lib/dbus/machine-id
    if command -v systemd-machine-id-setup >/dev/null; then
        run systemd-machine-id-setup
    elif command -v dbus-uuidgen >/dev/null; then
        run dbus-uuidgen --ensure=/etc/machine-id
    fi
    if [[ -d /var/lib/dbus && ! -e /var/lib/dbus/machine-id ]]; then
        run ln -s /etc/machine-id /var/lib/dbus/machine-id
    fi
    log_info "  machine-id: $(cat /etc/machine-id 2>/dev/null || echo '?')"

    # SSH host keys
    if pkg_installed openssh-server; then
        local k
        for k in /etc/ssh/ssh_host_*; do [[ -e "$k" ]] && backup_system_file "$k"; done
        run rm -f /etc/ssh/ssh_host_*
        run env DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive openssh-server
        if [[ "$SYSTEMD_RUNNING" == true ]]; then
            run systemctl try-restart ssh.service || true
        fi
        add_warning "SSH host keys пересозданы: клиенты увидят смену ключа (ssh-keygen -R <host>)."
    fi
    REBOOT_REQUIRED=true
}

# -----------------------------------------------------------------------------
# lvm — переименование группы томов в стандартное для Debian "<hostname>-vg".
#
# Порядок (всё, что можно проверить, проверяется ДО vgrename):
#   1. корень на LVM? /boot не в той же VG? новое имя свободно?
#   2. подготовка исправленных копий fstab/crypttab/resume/grub во временном каталоге;
#   3. показ изменений и подтверждение;
#   4. бэкап -> vgrename -> установка файлов -> update-initramfs -> update-grub;
#   5. при любой ошибке после vgrename — автоматический откат.
#
# Имена устройств: /dev/VG/LV и /dev/mapper/VG-LV, где в mapper-имени
# дефисы удваиваются: VG "srv-01-vg" -> "/dev/mapper/srv--01--vg-root".
# -----------------------------------------------------------------------------
LVM_FILES=(/etc/fstab /etc/crypttab /etc/initramfs-tools/conf.d/resume /etc/default/grub /boot/grub/grub.cfg)

step_lvm() {
    log_step "Имя группы томов LVM"

    if [[ "$DO_LVM" == no ]]; then
        log_info "Не запрошено"
        return 0
    fi
    if ! command -v lvs >/dev/null; then
        log_info "lvm2 не установлен — система не на LVM, пропуск"
        return 0
    fi

    local root_src old_vg boot_src boot_vg
    root_src="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
    old_vg="$(lvs --noheadings -o vg_name -- "$root_src" 2>/dev/null | tr -d '[:space:]' || true)"
    if [[ -z "$old_vg" ]]; then
        log_info "Корень ($root_src) не на LVM — пропуск"
        return 0
    fi

    local new_vg="${VG_NAME:-$(current_hostname)-vg}"
    log_info "Корень: $root_src, VG: $old_vg, целевое имя: $new_vg"

    if [[ "$old_vg" == "$new_vg" ]]; then
        log_info "VG уже называется $new_vg — изменений нет"
        return 0
    fi
    if [[ "$DO_LVM" == ask ]]; then
        ask_yn "Переименовать VG $old_vg -> $new_vg?" n || { log_info "Пропущено"; return 0; }
    fi

    # --- Проверки -------------------------------------------------------------
    [[ "$new_vg" =~ ^[A-Za-z0-9+_.][A-Za-z0-9+_.-]{0,126}$ && "$new_vg" != . && "$new_vg" != .. ]] \
        || die "Недопустимое имя VG: $new_vg"
    if vgs -- "$new_vg" >/dev/null 2>&1; then
        die "VG с именем $new_vg уже существует"
    fi
    boot_src="$(findmnt -n -o SOURCE /boot 2>/dev/null || echo "$root_src")"
    boot_vg="$(lvs --noheadings -o vg_name -- "$boot_src" 2>/dev/null | tr -d '[:space:]' || true)"
    if [[ "$boot_vg" == "$old_vg" ]]; then
        add_warning "/boot находится в VG $old_vg: после переименования потребуется grub-install. Автоматически не выполняю."
        return 0
    fi

    # --- Подготовка исправленных копий ---------------------------------------
    local old_m="${old_vg//-/--}" new_m="${new_vg//-/--}"
    local re_m re_d rep_m rep_d
    re_m="$(sed_escape_re "/dev/mapper/${old_m}-")"
    re_d="$(sed_escape_re "/dev/${old_vg}/")"
    rep_m="$(sed_escape_rep "/dev/mapper/${new_m}-")"
    rep_d="$(sed_escape_rep "/dev/${new_vg}/")"

    local work f changed=()
    work="$(mktemp -d)"
    for f in "${LVM_FILES[@]}" /etc/default/grub.d/*.cfg; do
        [[ -f "$f" ]] || continue
        mkdir -p "$work$(dirname "$f")"
        sed -e "s/${re_m}/${rep_m}/g" -e "s/${re_d}/${rep_d}/g" "$f" > "$work$f"
        if ! cmp -s "$f" "$work$f"; then
            changed+=("$f")
            echo "  --- $f"
            diff "$f" "$work$f" | sed -n 's/^[<>] /    &/p' | head -20 || true
        fi
    done
    if (( ${#changed[@]} == 0 )); then
        log_info "Ссылок на /dev/mapper/${old_m}-* и /dev/${old_vg}/* не найдено (используются UUID)"
    fi

    if ! confirm "Выполнить переименование VG $old_vg -> $new_vg и обновить файлы выше?"; then
        log_info "Отменено — система не изменена"
        rm -rf "$work"
        return 0
    fi
    if [[ "$DRY_RUN" == true ]]; then
        log_dry "vgrename $old_vg $new_vg; установка ${changed[*]:-—}; update-initramfs -u -k all; update-grub"
        rm -rf "$work"
        return 0
    fi

    # --- Выполнение с откатом ---------------------------------------------
    for f in "${changed[@]}"; do backup_system_file "$f"; done

    _lvm_rollback() {
        log_error "Ошибка — откат переименования VG"
        vgrename -- "$new_vg" "$old_vg" || log_error "Не удалось вернуть имя VG! Выполните вручную: vgrename $new_vg $old_vg"
        local b
        for b in "${changed[@]}"; do
            [[ -f "$BACKUP_DIR$b" ]] && cp -a -- "$BACKUP_DIR$b" "$b"
        done
        update-initramfs -u -k all || true
        log_error "Откат выполнен. Бэкапы: $BACKUP_DIR"
        exit 1
    }

    local saved_err_trap
    saved_err_trap="$(trap -p ERR)"
    vgrename -- "$old_vg" "$new_vg" || die "vgrename завершился с ошибкой — система не изменена"
    trap _lvm_rollback ERR
    for f in "${changed[@]}"; do
        cat -- "$work$f" > "$f"
    done
    log_info "Файлы обновлены: ${changed[*]:-—}"
    log_info "update-initramfs -u -k all ..."
    update-initramfs -u -k all
    if command -v update-grub >/dev/null; then
        log_info "update-grub ..."
        update-grub
        # update-grub должен сам подхватить новое имя; если нет — оставить
        # нашу исправленную копию grub.cfg, чтобы система точно загрузилась.
        if grep -q -- "/dev/mapper/${old_m}-" /boot/grub/grub.cfg 2>/dev/null; then
            add_warning "update-grub оставил старое имя VG в grub.cfg — установлена исправленная копия"
            cat -- "$work/boot/grub/grub.cfg" > /boot/grub/grub.cfg
        fi
    fi
    trap - ERR
    [[ -n "$saved_err_trap" ]] && eval "$saved_err_trap"
    unset -f _lvm_rollback
    rm -rf "$work"

    log_info "VG переименована: $old_vg -> $new_vg"
    REBOOT_REQUIRED=true
}
