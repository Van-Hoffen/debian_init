# ~/.bash_aliases
# Подключается автоматически из ~/.bashrc
# Все пользовательские псевдонимы и функции хранятся здесь.

# ── Навигация ──────────────────────────────────────────────────────────────
alias ..='cd ..'                        # Перейти на уровень вверх
alias ...='cd ../..'                    # Перейти на два уровня вверх
alias ....='cd ../../..'                # Перейти на три уровня вверх
alias ~='cd ~'                          # Перейти в домашнюю директорию
alias -- -='cd -'                       # Вернуться в предыдущую директорию
alias lsa='ls -alh'                     # Выполнить листинг директории полностью

# ── Работа с файлами ───────────────────────────────────────────────────────
alias cp='cp -iv'                       # Копировать: спросить если файл существует
alias mv='mv -iv'                       # Переместить: спросить перед перезаписью
alias rm='rm -Iv'                       # Удалить: подтверждение при 3+ файлах
alias mkdir='mkdir -pv'                 # Создать папку включая все вложенные
alias df='df -h'                        # Место на дисках в читаемом виде (GB/MB)
alias du='du -h'                        # Размер файлов/папок в читаемом виде
alias duh='du -sh *'                    # Размер всего содержимого текущей папки
alias cx='chmod +x'                     # Сделать файл исполняемым

# ── Система и процессы ─────────────────────────────────────────────────────
alias ps='ps aux'                       # Показать все запущенные процессы
alias psg='ps aux | grep'               # Найти процесс по имени: psg nginx
alias top='top -d 1'                    # Мониторинг процессов, обновление 1 сек
alias free='free -h'                    # Оперативная память в читаемом виде
alias ports='ss -tulnp'                 # Показать все открытые порты
alias myip='curl -s ifconfig.me'        # Узнать внешний IP адрес
if [ "$(id -u)" -eq 0 ]; then
    # ROOT  без SUDO 
    alias reboot='reboot'               # Перезагрузить сервер
    alias poweroff='poweroff'           # Выключить сервер
else
    # USER  SUDO
    alias reboot='sudo reboot'          # Перезагрузить сервер
    alias poweroff='sudo poweroff'      # Выключить сервер
fi

# ── Обновление системы ALT Linux ───────────────────────────────────────────
# ALT p9 и старше (apt-get):
alias update='sudo apt-get update && sudo apt-get upgrade -y'
alias apt='apt-get'
# ALT p10+ (dnf):
#if [ "$(id -u)" -eq 0 ]; then
    # ROOT  без SUDO
#    alias update='apt-get update -y'      # Обновить все пакеты системы
#else
    # USER — SUDOfi
#    alias update='sudo apt-get update -y'      # Обновить все пакеты системы
#fi

# ── Редактирование конфигов ────────────────────────────────────────────────
alias ebrc='${EDITOR:-nano} ~/.bashrc && source ~/.bashrc'      # Редактировать .bashrc и сразу применить
alias ebal='${EDITOR:-nano} ~/.bash_aliases && source ~/.bash_aliases'  # Редактировать алиасы и применить
alias sbrc='source ~/.bashrc'                                   # Применить .bashrc без перезахода
if [ "$(id -u)" -eq 0 ]; then
    # ROOT  без SUDO
    alias hosts='${EDITOR:-nano} /etc/hosts'                   # Редактировать файл hosts
else
    # USER — SUDOfi
    alias hosts='sudo ${EDITOR:-nano} /etc/hosts'                   # Редактировать файл hosts
fi

# ── Git ────────────────────────────────────────────────────────────────────
alias g='git'                           # Короткий вызов git
alias gs='git status'                   # Статус репозитория
alias ga='git add .'                    # Добавить все изменения в индекс
alias gc='git commit -m'                # Создать коммит: gc "сообщение"
alias gp='git push'                     # Отправить изменения на удалённый репо
alias gl='git log --oneline --graph --decorate -15'  # Красивый лог последних 15 коммитов
alias gd='git diff'                     # Показать незакоммиченные изменения
alias gb='git branch'                   # Список веток репозитория
alias gco='git checkout'                # Переключиться на ветку: gco main

# ── Сеть и SSH ─────────────────────────────────────────────────────────────
alias ping='ping -c 5'                  # Пинг только 5 раз, не бесконечно
alias wget='wget -c'                    # Скачать файл с продолжением при обрыве
alias ssha='eval $(ssh-agent) && ssh-add'  # Запустить ssh-agent и добавить ключ

# ── Удобные утилиты ────────────────────────────────────────────────────────
alias gnc='grep -Ev "^\s*(#|$|;)"'     # Показать файл без комментариев: cat file | gnc
alias h='history | grep'               # Поиск по истории команд: h "слово"
alias path='echo $PATH | tr ":" "\n"'  # Показать PATH каждый элемент с новой строки
alias now='date +"%T %d-%m-%Y"'        # Текущая дата и время: ЧЧ:ММ:СС ДД-ММ-ГГГГ
alias week='date +%V'                  # Номер текущей недели в году
alias mnt='mount | column -t | grep ^/dev/'   # Показать смонтированные разделы
alias disk='du -aBM 2>/dev/null | sort -nr | head -n 30'  # Топ 30 самых тяжёлых файлов

# ── Функции ────────────────────────────────────────────────────────────────

# extract — универсальная распаковка архивов любого формата
extract() {
    if [ -z "$1" ]; then
        echo "Использование: extract <файл>"
        return 1
    fi
    if [ ! -f "$1" ]; then
        echo "Файл '$1' не найден."
        return 1
    fi
    case "$1" in
        *.tar.bz2)  tar xjf "$1"            ;;  # TAR + BZIP2
        *.tar.gz)   tar xzf "$1"            ;;  # TAR + GZIP
        *.tar.xz)   tar xJf "$1"            ;;  # TAR + XZ
        *.tar.zst)  tar --zstd -xf "$1"     ;;  # TAR + ZSTD
        *.zip)      unzip "$1"              ;;  # ZIP архив
        *.7z)       7z x "$1"               ;;  # 7-Zip архив
        *.gz)       gunzip "$1"             ;;  # Одиночный GZIP
        *.bz2)      bunzip2 "$1"            ;;  # Одиночный BZIP2
        *.rar)      unrar x "$1"            ;;  # RAR архив
        *.xz)       xz -d "$1"             ;;  # Одиночный XZ
        *)          echo "Не знаю как распаковать '$1'" ;;
    esac
}

# mkcd — создать директорию и сразу войти в неё
# пример 
# 'mkcd /tmp/projects/myapp/config'
mkcd() { mkdir -p "$1" && cd "$1"; }

## Файлы и архивы
# Создать бэкап файла с датой: bak nginx.conf → nginx.conf.2026-04-28.bak 
bak() { cp "$1" "$1.$(date +%F).bak"; } 
# Найти файл по имени в текущей папке: ff nginx 
ff() { find . -name "*$1*" 2>/dev/null; } 
# Найти файл содержащий текст: ft "error" или ft "error" /var/log 
ft() { grep -rl "$1" "${2:-.}" 2>/dev/null; }

## Сеть
# Показать все IP адреса машины 
ips() { ip -br addr show | awk '{print $1, $3}'; } 
# Проверить доступность порта: chkport 192.168.1.1 22 
chkport() { timeout 2 bash -c "cat < /dev/null > /dev/tcp/$1/$2" && echo "Открыт" || echo "Закрыт"; } 
# Скачать и сразу распаковать tar.gz по URL 
dlx() { wget -qO- "$1" | tar xzf -; }

## Система
# Показать топ 10 процессов по памяти 
memtop() { ps aux --sort=-%mem | head -n 11; } 
# Показать топ 10 процессов по CPU 
cputop() { ps aux --sort=-%cpu | head -n 11; } 
# Сколько дней работает сервер — красиво 
uptime() { /usr/bin/uptime -p; } 
# Показать содержимое PATH каждый элемент с новой строки и номером 
pathlist() { echo "$PATH" | tr ':' '\n' | nl; }

## Разработка / текст
# Быстро создать и открыть файл в редакторе 
new() { touch "$1" && ${EDITOR:-nano} "$1"; } 
# Показать последние N строк лога в реальном времени: tailf /var/log/syslog 50 
tailf() { tail -n "${2:-20}" -f "$1"; } 
# Повторить команду каждые N секунд: every 2 df -h 
every() { local n=$1; shift; while true; do clear; "$@"; sleep "$n"; done; }

## Безопасность / пароли
# Сгенерировать случайный пароль нужной длины: genpass 20 
genpass() { tr -dc 'A-Za-z0-9!@#$%' </dev/urandom | head -c "${1:-16}"; echo; }

## Самые любимые в народе
# По опыту сообщества чаще всего используются `ff`, `bak`, `memtop` и `genpass` — они закрывают задачи которые возникают почти каждый день при работе с сервером.
