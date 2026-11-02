# ~/.bashrc — выполняется bash для интерактивных не-login оболочек.
#
# Файл устанавливается проектом debian_init (files/home/.bashrc) в /root,
# /etc/skel и (по запросу) в домашние каталоги пользователей. При повторной
# установке отличающаяся версия сохраняется как ~/.bashrc.~N~.
#
# ЛИЧНЫЕ НАСТРОЙКИ держите не здесь, а в файлах, которые установщик не трогает:
#   ~/.user_aliases  — свои алиасы (подключается в разделе 7)
#   ~/.bashrc.local  — любые свои настройки (подключается в конце, раздел 11)
#
# Зависимости: /etc/bash/.bash_aliases, /etc/bash/.bash_welcome (ставит
# install.sh), пакеты tmux, bash-completion, fastfetch (необязательно).

# ──────────────────────────────────────────────
# 1. ПОДКЛЮЧЕНИЕ ГЛОБАЛЬНОГО /etc/bashrc
# ──────────────────────────────────────────────
# В Debian общий файл /etc/bash.bashrc bash подключает сам.
# /etc/bashrc существует в ALT Linux / RHEL — подключаем, если есть.
if [ -r /etc/bashrc ]; then
    . /etc/bashrc
fi

# Если не интерактивная оболочка — ничего не делаем
case $- in
    *i*) ;;
      *) return;;
esac

# ──────────────────────────────────────────────
# 2. ИСТОРИЯ КОМАНД
# ──────────────────────────────────────────────
# Не сохранять дубли и строки начинающиеся с пробела
HISTCONTROL=ignoreboth

# Дописывать в файл истории, не перезаписывать
shopt -s histappend

# Размер истории (в памяти и на диске).
# HISTFILESIZE не должен быть меньше HISTSIZE, иначе на диск попадёт меньше,
# чем хранится в памяти (раньше было 6000 при 10000 в памяти).
HISTSIZE=10000
HISTFILESIZE=10000

# Временная метка для каждой команды в истории
HISTTIMEFORMAT='[%F_%T] '

# Немедленная запись в файл истории после каждой команды
export PROMPT_COMMAND='history -a'

# ──────────────────────────────────────────────
# 3. ПАРАМЕТРЫ ОБОЛОЧКИ (shopt)
# ──────────────────────────────────────────────
# Обновлять LINES и COLUMNS после каждой команды
shopt -s checkwinsize

# Рекурсивный glob (**) — совпадает со всеми файлами и вложенными каталогами
shopt -s globstar

# Исправление опечаток при cd (cd /Etc → cd /etc)
shopt -s cdspell

# Регистронезависимый glob.
# Внимание: rm *.log удалит и *.LOG — на сервере это стоит помнить.
shopt -s nocaseglob

# ──────────────────────────────────────────────
# 4. ПОДДЕРЖКА 256 ЦВЕТОВ В ТЕРМИНАЛЕ
# ──────────────────────────────────────────────
case "$TERM" in
    'xterm')   TERM=xterm-256color;;
    'screen')  TERM=screen-256color;;
    'Eterm')   TERM=Eterm-256color;;
    xterm-color|*-256color) color_prompt=yes;;
esac

# Принудительная поддержка цветов для ttyS0 (Proxmox Serial Console)
# ttyS0 определяется как vt100 — принудительно задаём xterm-256color
if [[ "$(tty)" == "/dev/ttyS0" ]]; then
    export TERM=xterm-256color
fi

force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# ──────────────────────────────────────────────
# 5. ПРОМПТ PS1 — ЦВЕТА ЧЕРЕЗ ПЕРЕМЕННЫЕ
# ──────────────────────────────────────────────
if [ "$color_prompt" = yes ]; then

    # --- Переменные цветов (без изменения самих цветов) ---
    C_RESET='\[\e[0m\]'
    C_BRACKET='\[\e[0;1;2m\]'              # Скобки/разделители (серый жирный)
    C_TIME='\[\e[0;1;2;4m\]'               # Время (жирный подчёркнутый)
    C_HIST_BR='\[\e[0;1;38;5;105m\]'       # Скобки номера истории (фиолетовый)
    C_HIST_NUM='\[\e[0;1;38;5;202m\]'      # Номер команды в истории (оранжевый)
    C_AT='\[\e[0;1;38;5;214m\]'            # Символ @ (жёлтый)
    C_HOST='\[\e[0;1;38;5;68m\]'           # Имя хоста (синий)
    C_COLON='\[\e[0;1m\]'                  # Двоеточие
    C_PATH='\[\e[0;2m\]'                   # Путь (тёмный)
    C_EXIT_BR='\[\e[0;1m\]'                # Скобки кода возврата
    C_SUFFIX='\[\e[0;1;2m\]'               # Символ $ / #
    C_USER_ROOT='\[\e[0;1;2;38;5;160m\]'   # root — красный
    C_USER_NORM='\[\e[0;1;2;38;5;112m\]'   # user — зелёный

    # --- Сборка PS1 из переменных ---
    _PS1_TIME="${C_BRACKET}[${C_TIME}\A${C_BRACKET}]"
    _PS1_HIST="${C_HIST_BR}[${C_HIST_NUM}\!${C_HIST_BR}]"
    _PS1_AT="${C_AT}@"
    _PS1_HOST="${C_HOST}\h"
    _PS1_PATH="${C_COLON}:${C_PATH}\w"
    _PS1_EXIT="${C_EXIT_BR}[${C_EXIT_BR}\$?${C_EXIT_BR}]"
    _PS1_SUFFIX="${C_SUFFIX}\$ ${C_RESET}"

    if [ "$(id -u)" -eq 0 ]; then
        # ROOT — имя пользователя красным
        _PS1_USER="${C_USER_ROOT}\u"
        PS1="${_PS1_TIME}${_PS1_HIST}${_PS1_USER}${_PS1_AT}${_PS1_HOST}${_PS1_PATH}${_PS1_EXIT}${_PS1_SUFFIX}"
    else
        # USER — имя пользователя зелёным
        _PS1_USER="${C_USER_NORM}\u"
        PS1="${_PS1_TIME}${_PS1_HIST}${_PS1_USER}${_PS1_AT}${_PS1_HOST}${_PS1_PATH}${_PS1_EXIT}${_PS1_SUFFIX}"
    fi
else
    PS1='\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Заголовок окна xterm/rxvt: user@host:dir
case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;\u@\h: \w\a\]$PS1"
        ;;
esac

# ──────────────────────────────────────────────
# 6. ЦВЕТА ДЛЯ ls, grep И GCC
# ──────────────────────────────────────────────
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# ──────────────────────────────────────────────
# 7. ПСЕВДОНИМЫ (ALIASES)
# ──────────────────────────────────────────────
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# Общесистемные алиасы (для всех пользователей)
if [ -f /etc/bash/.bash_aliases ]; then
    . /etc/bash/.bash_aliases
fi

# Личные алиасы пользователя (перекрывают общие если совпадают)
if [ -f ~/.user_aliases ]; then
    . ~/.user_aliases
fi

# ──────────────────────────────────────────────
# 8. АВТОДОПОЛНЕНИЕ (BASH-COMPLETION)
# ──────────────────────────────────────────────
# Debian: пакет bash-completion (ставится install.sh).
# Если completion уже подключён глобально — повторное подключение безвредно.
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# ──────────────────────────────────────────────
# 9. TMUX — автозапуск и функция управления
# ──────────────────────────────────────────────
tmux_run() {
    local me real_tmux
    me=$(whoami)
    real_tmux=$(command -v tmux)

    if [ -z "$real_tmux" ]; then
        echo "tmux не найден."
        return 1
    fi

    export TERM="xterm-256color"

    # Вызов с аргументами — передать напрямую
    if [ "$#" -gt 0 ]; then
        command tmux "$@"
        return
    fi

    # Уже внутри tmux — ничего не делать
    if [[ -n "$TMUX" ]]; then
        return
    fi

    if command tmux has-session -t "$me" 2>/dev/null; then
        # Сессия есть — подключиться
        command tmux attach-session -t "$me"
    else
        # Новая сессия — создать с флагом TMUX_NEW_SESSION (по нему секция 10
        # покажет welcome один раз) и подключиться.
        # Флаг задаётся сразу при создании (-e, tmux >= 3.2): раньше setenv
        # выполнялся после старта оболочки и мог не успеть (гонка).
        command tmux new-session -d -s "$me" -e TMUX_NEW_SESSION=1
        command tmux attach-session -t "$me"
    fi
}
alias tmux='tmux_run'

# Автозапуск при SSH и ttyS0 — используем ту же функцию.
# Проверяем наличие tmux, чтобы не печатать ошибку при каждом входе.
# _TMUX_AUTOSTARTED нужен секции 10: после выхода/detach из tmux внешняя
# оболочка не должна повторно показывать welcome screen.
if [[ -z "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
    if [[ -n "$SSH_TTY" || "$(tty)" == "/dev/ttyS0" ]]; then
        _TMUX_AUTOSTARTED=1
        tmux_run
    fi
fi

# ──────────────────────────────────────────────
# 10. WELCOME SCREEN
# ──────────────────────────────────────────────
if [[ $- == *i* ]]; then
    if [[ -n "$TMUX" ]]; then
        # Внутри tmux — показать только если новая сессия
        _tmux_new=$(tmux showenv TMUX_NEW_SESSION 2>/dev/null | grep -v '^-')
        if [[ -n "$_tmux_new" ]]; then
            # Сбросить флаг и показать welcome
            tmux setenv -u TMUX_NEW_SESSION
            unset _tmux_new
            if [ -f /etc/bash/.bash_welcome ]; then
                . /etc/bash/.bash_welcome
                welcome_screen
            elif command -v fastfetch &>/dev/null; then
                fastfetch
            fi
        fi
    elif [[ -z "$TMUX" && -z "$_TMUX_AUTOSTARTED" ]]; then
        # Вне tmux (и tmux не запускался автоматически) — показать сразу
        if [ -f /etc/bash/.bash_welcome ]; then
            . /etc/bash/.bash_welcome
            welcome_screen
        elif command -v fastfetch &>/dev/null; then
            fastfetch
        fi
    fi
fi
unset _TMUX_AUTOSTARTED

# ──────────────────────────────────────────────
# 11. ЛИЧНЫЕ НАСТРОЙКИ ПОЛЬЗОВАТЕЛЯ
# ──────────────────────────────────────────────
# ~/.bashrc.local не создаётся и не перезаписывается установщиком —
# всё, что нужно только вам, добавляйте туда.
if [ -f ~/.bashrc.local ]; then
    . ~/.bashrc.local
fi
