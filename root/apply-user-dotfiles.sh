#!/usr/bin/env bash
# =============================================================================
# apply-user-dotfiles.sh
# Копирует .bashrc и .tmux.conf из /root во все домашние каталоги реальных
# пользователей системы, предварительно делая нумерованный бэкап существующих
# файлов. После копирования восстанавливает права владельца.
#
# Использование: sudo bash apply-user-dotfiles.sh [--dry-run]
# =============================================================================
set -euo pipefail

# --- Параметры ---------------------------------------------------------------
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Исходные файлы (берём из /root)
DOTFILES=(
    "/root/.bashrc"
    "/root/.tmux.conf"
)

# --- Цвета для вывода --------------------------------------------------------
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RESET='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${RESET}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
log_error() { echo -e "${RED}[ERR] ${RESET}  $*" >&2; }

# --- Проверка запуска от root ------------------------------------------------
if [[ "$EUID" -ne 0 ]]; then
    log_error "Скрипт должен запускаться от root (sudo)."
    exit 1
fi

# --- Проверяем наличие исходных файлов ---------------------------------------
for src in "${DOTFILES[@]}"; do
    if [[ ! -f "$src" ]]; then
        log_error "Исходный файл не найден: $src — прерываем."
        exit 1
    fi
done

# --- Определяем минимальный UID для реальных пользователей ------------------
# Берём из /etc/login.defs, если нет — используем 1000 по умолчанию
UID_MIN="$(awk '/^\s*UID_MIN\s+/ {print $2}' /etc/login.defs 2>/dev/null | tail -n1)"
UID_MIN="${UID_MIN:-1000}"
log_info "UID_MIN = $UID_MIN"

$DRY_RUN && log_warn "Режим DRY-RUN: реальные изменения не вносятся."

# --- Счётчики для итогов -----------------------------------------------------
count_ok=0
count_skip=0
count_err=0

# =============================================================================
# Основной цикл по пользователям
# Фильтруем из базы пользователей:
#   - UID >= UID_MIN         (не системные)
#   - имя != nobody          (псевдо-пользователь)
#   - домашний каталог = /…  (явно указан)
#   - shell не nologin/false (интерактивный)
# =============================================================================
while IFS=: read -r user _ uid _ _ home shell; do
    # --- Фильтры -------------------------------------------------------------
    [[ "$uid" -lt "$UID_MIN" ]]              && continue
    [[ "$user" == "nobody" ]]                && continue
    [[ "$home" != /* ]]                      && continue
    [[ "$shell" =~ (nologin|false|sync)$ ]]  && continue

    # Каталог должен существовать и быть именно директорией
    if [[ ! -d "$home" ]]; then
        log_warn "Каталог $home не существует — пропускаем $user."
        (( count_skip++ )) || true
        continue
    fi

    echo
    log_info "==> Пользователь: $user  (home: $home)"

    # --- Определяем primary group пользователя -------------------------------
    user_group="$(id -gn "$user" 2>/dev/null || echo "$user")"

    # --- Обрабатываем каждый dotfile -----------------------------------------
    for src in "${DOTFILES[@]}"; do
        file="$(basename "$src")"
        dst="$home/$file"

        # -- Резервная копия (если файл уже существует) -----------------------
        # ВАЖНО: сначала делаем бэкап, ПОТОМ копируем — иначе cp жалуется
        # что src == dst (именно эта ошибка была в предыдущей версии)
        if [[ -e "$dst" ]]; then
            if $DRY_RUN; then
                log_info "  [DRY] Бэкап: $dst -> ${dst}.~N~"
            else
                # --backup=numbered создаёт .~1~, .~2~, … автоматически
                cp --backup=numbered -p "$dst" "$dst.bak_tmp_$$" 2>/dev/null
                # Переименовываем в нумерованный формат вручную, т.к. нельзя
                # делать cp файла в самого себя даже с --backup
                n=1
                while [[ -e "${dst}.~${n}~" ]]; do (( n++ )) || true; done
                mv "$dst.bak_tmp_$$" "${dst}.~${n}~"
                log_info "  Бэкап: $dst -> ${dst}.~${n}~"
            fi
        fi

        # -- Копирование из /root ---------------------------------------------
        if $DRY_RUN; then
            log_info "  [DRY] Копирование: $src -> $dst"
        else
            if cp -f "$src" "$dst"; then
                # -- Права: владелец = пользователь, чтение-запись только ему -
                chown "$user:$user_group" "$dst"
                chmod 0644 "$dst"
                log_info "  Скопировано: $dst  (chown $user:$user_group, chmod 644)"
            else
                log_error "  Ошибка копирования $src -> $dst"
                (( count_err++ )) || true
                continue
            fi
        fi
    done

    (( count_ok++ )) || true

done < <(getent passwd)

# --- Итоги -------------------------------------------------------------------
echo
log_info "Готово. Обработано: $count_ok  Пропущено: $count_skip  Ошибок: $count_err"
$DRY_RUN && log_warn "Это был DRY-RUN — никаких файлов не изменено."
