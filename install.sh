#!/usr/bin/env bash
# =============================================================================
# install.sh — оркестратор инициализации Debian.
#
# Сценарии (--mode):
#   fresh     — только что установленная система. Переименование компьютера и
#               группы LVM — только по флагам --hostname / --rename-vg.
#   template  — клон из шаблона VM. Спрашивает про имя компьютера, VG и
#               генерацию новых machine-id / SSH host keys.
#   existing  — уже используемая машина. Как template (без machine-id), плюс
#               раздаёт .bashrc / .tmux.conf всем существующим пользователям.
#
# Запуск: от root (на netinst sudo может отсутствовать: `su -`).
# Подробности: ./install.sh --help, README.md
# =============================================================================
set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/debian_init.log"

# shellcheck source=lib/common.sh
. "$REPO_DIR/lib/common.sh"
for _m in "$REPO_DIR"/modules/*.sh; do
    # shellcheck disable=SC1090
    . "$_m"
done
unset _m

# Порядок шагов. preflight выполняется всегда.
ALL_STEPS=(preflight upgrade packages system-files dotfiles users hostname identity lvm zabbix extras)

usage() {
    cat <<EOF
Использование: ./install.sh [--mode fresh|template|existing] [параметры]

Режимы:
  --mode fresh        Новая система: настройки, обновление, пакеты.
                      Имя/VG меняются только если заданы --hostname/--rename-vg.
  --mode template     Клон шаблона: + вопросы про имя, VG, machine-id/SSH-ключи.
  --mode existing     Рабочая машина: + .bashrc/.tmux.conf всем пользователям.
  Без --mode в терминале будет показано меню.

Имя компьютера и LVM:
  --hostname NAME     Новое имя компьютера.
  --rename-vg         Переименовать VG корня в "<hostname>-vg".
  --no-rename-vg      Не переименовывать VG (и не спрашивать).
  --vg-name NAME      Явное имя VG вместо "<hostname>-vg".
  --reset-identity    Новые machine-id и SSH host keys.
  --no-reset-identity Не трогать machine-id и SSH host keys.

Пользователи:
  --all-users         Раздать dotfiles всем существующим пользователям.
  --no-all-users      Не раздавать (только /root и /etc/skel).

Пакеты и компоненты:
  --platform auto|hw|vm|kvm|microsoft|vmware   Тип машины (по умолчанию auto).
  --zabbix-server ADDR       Настроить zabbix-agent2 на этот сервер.
  --extras LIST|all          Доп. компоненты: ${EXTRAS_ALL[*]}
  --extras-user USER         Для кого ставить extras (по умолчанию SUDO_USER).
  --git-name NAME / --git-email EMAIL   Для компонента gitconfig.

Управление выполнением:
  --only STEP[,STEP]  Выполнить только указанные шаги.
  --skip STEP[,STEP]  Пропустить шаги.
  --list-steps        Показать шаги и выйти.
  -y, --yes           Без вопросов (значения по умолчанию, подтверждения = да).
  -n, --dry-run       Показать действия, ничего не меняя.
  -h, --help          Эта справка.

Шаги: ${ALL_STEPS[*]}

Примеры:
  ./install.sh --mode fresh --hostname srv-web01 --rename-vg -y
  ./install.sh --mode template
  ./install.sh --mode existing --dry-run
  ./install.sh --only hostname,lvm --hostname srv-db02 --rename-vg
  ./install.sh --only extras --extras docker,node --extras-user ivan
EOF
}

# --- Параметры по умолчанию ---------------------------------------------------
MODE=""
NEW_HOSTNAME=""
VG_NAME=""
DO_HOSTNAME=""     # yes|no|ask — вычисляется из режима, если пусто
DO_LVM=""
DO_IDENTITY=""
DO_USERS=""
PLATFORM="auto"
ZABBIX_SERVER=""
EXTRAS=""
EXTRAS_USER=""
GIT_NAME=""
GIT_EMAIL=""
ONLY=""
SKIP=""
ORIG_ARGS=("$@")

need_arg() { [[ $# -ge 2 && -n "$2" ]] || die "Параметр $1 требует значение"; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)              need_arg "$@"; MODE="$2"; shift ;;
        --hostname)          need_arg "$@"; NEW_HOSTNAME="$2"; shift ;;
        --rename-vg)         DO_LVM=yes ;;
        --no-rename-vg)      DO_LVM=no ;;
        --vg-name)           need_arg "$@"; VG_NAME="$2"; DO_LVM="${DO_LVM:-yes}"; shift ;;
        --reset-identity)    DO_IDENTITY=yes ;;
        --no-reset-identity) DO_IDENTITY=no ;;
        --all-users)         DO_USERS=yes ;;
        --no-all-users)      DO_USERS=no ;;
        --platform)          need_arg "$@"; PLATFORM="$2"; shift ;;
        --zabbix-server)     need_arg "$@"; ZABBIX_SERVER="$2"; shift ;;
        --extras)            need_arg "$@"; EXTRAS="$2"; shift ;;
        --extras-user)       need_arg "$@"; EXTRAS_USER="$2"; shift ;;
        --git-name)          need_arg "$@"; GIT_NAME="$2"; shift ;;
        --git-email)         need_arg "$@"; GIT_EMAIL="$2"; shift ;;
        --only)              need_arg "$@"; ONLY="$2"; shift ;;
        --skip)              need_arg "$@"; SKIP="$2"; shift ;;
        --list-steps)        printf '%s\n' "${ALL_STEPS[@]}"; exit 0 ;;
        -y|--yes)            ASSUME_YES=true ;;
        -n|--dry-run)        DRY_RUN=true ;;
        -h|--help)           usage; exit 0 ;;
        *)                   usage >&2; die "Неизвестный параметр: $1" ;;
    esac
    shift
done

# --- root -------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    if command -v sudo >/dev/null; then
        log_info "Перезапуск через sudo..."
        exec sudo -E bash "$0" "${ORIG_ARGS[@]}"
    fi
    die "Нужны права root. sudo не установлен — выполните: su -  и затем  cd $REPO_DIR && ./install.sh ${ORIG_ARGS[*]}"
fi

# --- Проверка значений --------------------------------------------------------
if [[ -n "$NEW_HOSTNAME" ]] && ! valid_hostname "$NEW_HOSTNAME"; then
    die "Недопустимое имя компьютера: '$NEW_HOSTNAME'"
fi
_check_steps() {
    local s
    for s in ${1//,/ }; do
        [[ " ${ALL_STEPS[*]} " == *" $s "* ]] || die "Неизвестный шаг: $s (см. --list-steps)"
    done
}
_check_steps "$ONLY"
_check_steps "$SKIP"

# --- Режим ---------------------------------------------------------------------
if [[ -z "$MODE" ]]; then
    if [[ -n "$ONLY" ]]; then
        MODE=custom           # --only без --mode: только явно указанные шаги
    elif is_interactive; then
        echo "Выберите сценарий:"
        echo "  1) fresh    — новая система"
        echo "  2) template — клон из шаблона"
        echo "  3) existing — уже используемая машина"
        while [[ -z "$MODE" ]]; do
            read -r -p "Номер [1-3]: " _r
            case "$_r" in 1) MODE=fresh ;; 2) MODE=template ;; 3) MODE=existing ;; esac
        done
    else
        die "Укажите --mode fresh|template|existing"
    fi
fi

case "$MODE" in
    fresh)
        : "${DO_HOSTNAME:=no}" "${DO_LVM:=no}" "${DO_IDENTITY:=no}" "${DO_USERS:=no}" ;;
    template)
        : "${DO_HOSTNAME:=ask}" "${DO_LVM:=ask}" "${DO_IDENTITY:=ask}" "${DO_USERS:=no}" ;;
    existing)
        : "${DO_HOSTNAME:=ask}" "${DO_LVM:=ask}" "${DO_IDENTITY:=no}" "${DO_USERS:=yes}" ;;
    custom)
        : "${DO_HOSTNAME:=ask}" "${DO_LVM:=ask}" "${DO_IDENTITY:=ask}" "${DO_USERS:=yes}" ;;
    *) die "Неизвестный режим: $MODE" ;;
esac
[[ -n "$NEW_HOSTNAME" ]] && DO_HOSTNAME=yes

# Нужно ли выполнять шаг
want_step() {
    local s="$1"
    [[ "$s" == preflight ]] && return 0
    if [[ -n "$ONLY" ]]; then
        [[ ",$ONLY," == *",$s,"* ]] || return 1
    fi
    [[ ",$SKIP," == *",$s,"* ]] && return 1
    # В режимах без раздачи пользователям шаг users пропускается
    [[ "$s" == users && "$DO_USERS" == no && -z "$ONLY" ]] && return 1
    return 0
}

# --- Окружение выполнения ---------------------------------------------------
[[ -d /run/systemd/system ]] && SYSTEMD_RUNNING=true
export DRY_RUN ASSUME_YES BACKUP_DIR SYSTEMD_RUNNING

# Один экземпляр одновременно
exec 9> /run/debian_init.lock 2>/dev/null || exec 9> /tmp/debian_init.lock
flock -n 9 || die "install.sh уже выполняется"

# Лог: весь вывод дублируется в $LOG_FILE
if [[ "$DRY_RUN" != true ]]; then
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo "===== $(date '+%F %T') install.sh ${ORIG_ARGS[*]} =====" >> "$LOG_FILE"
fi

on_error() {
    local rc=$? line="$1" cmd="$2"
    log_error "Ошибка (код $rc) в строке $line: $cmd"
    log_error "Лог: $LOG_FILE; бэкапы: $BACKUP_DIR"
    exit "$rc"
}
trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR

# --- Выполнение ---------------------------------------------------------------
log_info "Режим: $MODE$([[ "$DRY_RUN" == true ]] && echo ' (DRY-RUN)')"
log_info "Каталог проекта: $REPO_DIR"

for step in "${ALL_STEPS[@]}"; do
    want_step "$step" || continue
    "step_${step//-/_}"
done

# --- Итоги -------------------------------------------------------------------
log_step "Готово"
[[ -d "$BACKUP_DIR" ]] && log_info "Бэкапы изменённых системных файлов: $BACKUP_DIR"
[[ "$DRY_RUN" != true ]] && log_info "Лог: $LOG_FILE"
if (( ${#WARNINGS[@]} )); then
    echo "${C_YEL}Предупреждения:${C_RST}"
    printf '  - %s\n' "${WARNINGS[@]}"
fi
if [[ "$REBOOT_REQUIRED" == true ]]; then
    echo "${C_YEL}Требуется перезагрузка: systemctl reboot${C_RST}"
fi
[[ "$DRY_RUN" == true ]] && log_warn "Это был DRY-RUN — изменений не внесено."
exit 0
