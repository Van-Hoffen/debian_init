# shellcheck shell=bash
# =============================================================================
# lib/common.sh — общие функции для install.sh и модулей.
# Подключается через `source`; сам по себе не исполняется.
#
# Требования: только bash, coreutils, apt-get/dpkg и util-linux — всё это есть
# на любой системе после Debian netinst. curl, sudo, git, lsb_release здесь НЕ
# используются.
# =============================================================================

# --- Глобальное состояние (заполняется install.sh) ---------------------------
: "${DRY_RUN:=false}"          # true — только показывать действия
: "${ASSUME_YES:=false}"       # true — не задавать вопросов, брать значения по умолчанию
: "${BACKUP_DIR:=/var/backups/debian_init/$(date +%Y%m%d-%H%M%S)}"
: "${SYSTEMD_RUNNING:=false}"  # true — система загружена с systemd (не chroot)
WARNINGS=()                    # предупреждения, выводятся в итоговой сводке
REBOOT_REQUIRED=false

# --- Цвета (отключаются, если вывод не в терминал) ---------------------------
if [[ -t 1 ]]; then
    C_RED=$'\e[0;31m'; C_GRN=$'\e[0;32m'; C_YEL=$'\e[1;33m'
    C_BLU=$'\e[1;34m'; C_DIM=$'\e[2m';    C_RST=$'\e[0m'
else
    C_RED=''; C_GRN=''; C_YEL=''; C_BLU=''; C_DIM=''; C_RST=''
fi

# --- Вывод -------------------------------------------------------------------
log_step()  { echo; echo "${C_BLU}==> $*${C_RST}"; }
log_info()  { echo "${C_GRN}[INFO]${C_RST} $*"; }
log_warn()  { echo "${C_YEL}[WARN]${C_RST} $*" >&2; }
log_error() { echo "${C_RED}[ERR] ${C_RST} $*" >&2; }
log_dry()   { echo "${C_DIM}[DRY]  $*${C_RST}"; }
die()       { log_error "$*"; exit 1; }

# Предупреждение, которое попадёт и в итоговую сводку
add_warning() { WARNINGS+=("$*"); log_warn "$*"; }

# --- Выполнение команд с учётом --dry-run ------------------------------------
# run cmd args...  — выполнить команду или (в dry-run) только показать её
run() {
    if [[ "$DRY_RUN" == true ]]; then
        log_dry "$*"
        return 0
    fi
    "$@"
}

# --- Вопросы пользователю ----------------------------------------------------
# Есть ли возможность задать вопрос (терминал и не --yes)
is_interactive() {
    [[ "$ASSUME_YES" != true && -t 0 ]]
}

# ask_yn "Вопрос" y|n — вернуть 0 (да) / 1 (нет).
# В неинтерактивном режиме возвращает значение по умолчанию.
ask_yn() {
    local question="$1" default="${2:-n}" hint reply
    [[ "$default" == y ]] && hint="[Y/n]" || hint="[y/N]"
    if ! is_interactive; then
        [[ "$default" == y ]]
        return
    fi
    while true; do
        read -r -p "${C_YEL}[?]${C_RST} ${question} ${hint}: " reply
        reply="${reply:-$default}"
        case "${reply,,}" in
            y|yes|д|да)  return 0 ;;
            n|no|н|нет)  return 1 ;;
            *) echo "  Ответьте y или n." ;;
        esac
    done
}

# confirm "Вопрос" — подтверждение явно запрошенного действия.
# При --yes считается подтверждённым, иначе по умолчанию «нет».
confirm() {
    [[ "$ASSUME_YES" == true ]] && return 0
    ask_yn "$1" n
}

# ask_value "Вопрос" [значение_по_умолчанию] — печатает ответ в stdout.
ask_value() {
    local question="$1" default="${2:-}" reply
    if ! is_interactive; then
        printf '%s' "$default"
        return
    fi
    if [[ -n "$default" ]]; then
        read -r -p "${C_YEL}[?]${C_RST} ${question} [${default}]: " reply
    else
        read -r -p "${C_YEL}[?]${C_RST} ${question}: " reply
    fi
    printf '%s' "${reply:-$default}"
}

# --- apt ---------------------------------------------------------------------
# Неинтерактивный apt-get: не задаёт вопросов о конфигах (оставляет текущие).
apt_get() {
    run env DEBIAN_FRONTEND=noninteractive apt-get -y -q \
        -o Dpkg::Options::=--force-confdef \
        -o Dpkg::Options::=--force-confold \
        "$@"
}

# Есть ли пакет в подключённых репозиториях (кандидат на установку)
pkg_available() {
    local cand
    cand="$(apt-cache policy -- "$1" 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
    [[ -n "$cand" && "$cand" != "(none)" ]]
}

pkg_installed() {
    dpkg-query -W -f='${Status}' -- "$1" 2>/dev/null | grep -q 'install ok installed'
}

# Прочитать список пакетов: по одному на строку, '#' — комментарий
read_list() {
    sed 's/#.*//; s/[[:space:]]//g; /^$/d' "$1"
}

# ensure_pkgs pkg... — установить недостающие пакеты, отсутствующие в
# репозиториях пропустить с предупреждением (а не падать целиком).
ensure_pkgs() {
    local p to_install=() missing=()
    for p in "$@"; do
        pkg_installed "$p" && continue
        if pkg_available "$p"; then
            to_install+=("$p")
        else
            missing+=("$p")
        fi
    done
    if (( ${#missing[@]} )); then
        add_warning "Пакеты отсутствуют в репозиториях и пропущены: ${missing[*]}"
    fi
    if (( ${#to_install[@]} )); then
        log_info "Установка: ${to_install[*]}"
        apt_get install "${to_install[@]}"
    fi
}

# --- Файлы -------------------------------------------------------------------
# Сохранить копию системного файла в $BACKUP_DIR с сохранением пути.
backup_system_file() {
    local f="$1"
    [[ -e "$f" ]] || return 0
    if [[ "$DRY_RUN" == true ]]; then
        log_dry "бэкап $f -> $BACKUP_DIR$f"
        return 0
    fi
    install -d -m 0700 "$BACKUP_DIR$(dirname "$f")"
    cp -a -- "$f" "$BACKUP_DIR$f"
}

# install_system_file SRC DST [MODE] [keep]
#   Ставит файл, принадлежащий root. Идемпотентно:
#   - DST совпадает с SRC         -> ничего не делаем;
#   - DST отличается              -> бэкап в $BACKUP_DIR и замена;
#   - режим keep и DST существует -> не трогаем (файл правится на сервере).
install_system_file() {
    local src="$1" dst="$2" mode="${3:-0644}" policy="${4:-replace}"
    if [[ -e "$dst" ]]; then
        if [[ "$policy" == keep ]]; then
            log_info "  $dst уже существует — оставлен без изменений"
            return 0
        fi
        if cmp -s -- "$src" "$dst"; then
            log_info "  $dst без изменений"
            return 0
        fi
        backup_system_file "$dst"
    fi
    if [[ "$DRY_RUN" == true ]]; then
        log_dry "install -m $mode $src -> $dst"
        return 0
    fi
    install -D -m "$mode" -o root -g root -- "$src" "$dst"
    log_info "  $dst обновлён"
}

# install_user_file USER SRC DST
#   Ставит файл в домашний каталог пользователя ОТ ИМЕНИ ЭТОГО ПОЛЬЗОВАТЕЛЯ
#   (runuser): подмена файла символической ссылкой не даст записать что-либо
#   за пределами прав пользователя. Существующий отличающийся файл сохраняется
#   рядом как DST.~N~ (нумерованный бэкап). Совпадающий — не трогается.
install_user_file() {
    local user="$1" src="$2" dst="$3" n=1 bak
    if [[ -L "$dst" ]]; then
        add_warning "$dst — символическая ссылка, пропущен (пользователь $user)"
        return 0
    fi
    if [[ -f "$dst" ]] && cmp -s -- "$src" "$dst"; then
        log_info "  $dst без изменений"
        return 0
    fi
    if [[ -e "$dst" ]]; then
        while [[ -e "${dst}.~${n}~" || -L "${dst}.~${n}~" ]]; do (( n++ )); done
        bak="${dst}.~${n}~"
    fi
    if [[ "$DRY_RUN" == true ]]; then
        [[ -n "${bak:-}" ]] && log_dry "бэкап $dst -> $bak"
        log_dry "$src -> $dst (владелец $user)"
        return 0
    fi
    # Содержимое передаётся через stdin: исходник может лежать в /root (0700).
    # shellcheck disable=SC2016
    runuser -u "$user" -- sh -c '
        set -e
        dst="$1"; bak="$2"
        [ -n "$bak" ] && cp -p -- "$dst" "$bak"
        tmp="$(mktemp "${dst}.XXXXXX")"
        cat > "$tmp"
        chmod 0644 "$tmp"
        mv -f -- "$tmp" "$dst"
    ' _ "$dst" "${bak:-}" < "$src"
    if [[ -n "${bak:-}" ]]; then
        log_info "  $dst обновлён (старая версия: $(basename "$bak"))"
    else
        log_info "  $dst создан"
    fi
}

# --- Прочее ------------------------------------------------------------------
# Экранирование строки для использования в регулярном выражении sed (BRE)
sed_escape_re()  { printf '%s' "$1" | sed 's/[][\.*^$/]/\\&/g'; }
# То же для расширенных регулярных выражений (sed -E, grep -E)
sed_escape_ere() { printf '%s' "$1" | sed 's/[][\.*^$/+?(){}|]/\\&/g'; }
# Экранирование строки для правой части s///
sed_escape_rep() { printf '%s' "$1" | sed 's/[\/&]/\\&/g'; }

# Имя хоста по RFC 1123: 1–63 символа, буквы/цифры/дефис, дефис не по краям
valid_hostname() {
    [[ "$1" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]]
}

# Текущее короткое имя хоста (из файла — работает и в chroot)
current_hostname() {
    local h
    h="$(head -n1 /etc/hostname 2>/dev/null || true)"
    [[ -n "$h" ]] || h="$(hostname 2>/dev/null || echo localhost)"
    printf '%s' "${h%%.*}"
}

# Минимальный UID обычных пользователей
uid_min() {
    local v
    v="$(awk '/^[[:space:]]*UID_MIN[[:space:]]+/ {print $2}' /etc/login.defs 2>/dev/null | tail -n1)"
    printf '%s' "${v:-1000}"
}

# Список «реальных» пользователей: user:group:home (UID >= UID_MIN,
# интерактивная оболочка, существующий каталог)
list_human_users() {
    local min user uid gid home shell
    min="$(uid_min)"
    while IFS=: read -r user _ uid gid _ home shell; do
        [[ "$uid" =~ ^[0-9]+$ ]] || continue
        (( uid >= min )) || continue
        [[ "$user" == nobody ]] && continue
        [[ "$home" == /* && -d "$home" ]] || continue
        [[ "$shell" =~ (nologin|false|sync)$ ]] && continue
        printf '%s:%s:%s\n' "$user" "$(id -gn "$user" 2>/dev/null || echo "$gid")" "$home"
    done < <(getent passwd)
}
