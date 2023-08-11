# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
#! Увеличиваем размер файла истории. 
HISTSIZE=10000
HISTFILESIZE=6000
#! Следующая команда допишет в файл /home/username/.bash_history время в которое запускалась комманда.
HISTTIMEFORMAT='[%F_%T] '
#!Save history file immideatly after each command.
export PROMPT_COMMAND='history -a'

#! check the window size after each command and, if necessary,
#! update the values of LINES and COLUMNS.
shopt -s checkwinsize

#! If set, the pattern "**" used in a pathname expansion context will
#! match all files and zero or more directories and subdirectories.
shopt -s globstar
#! Следующие комманды позволит некоторые ошибки при перемещении между директориями.
shopt -s cdspell
#! например cd /Etc = cd /etc
shopt -s nocaseglob

# make less more friendly for non-text input files, see lesspipe(1)
# [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#! Раскоментировали данную строку т.к. хотим цветовую схему при работе с консолью.
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    if [ $(id -u) -eq 0 ];
        then # you are root, make the prompt red
#!standard PS            PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
#! ROOT = RED
			PS1='\[\e[0;1;2m\][\[\e[0;1;2;4m\]\A\[\e[0;1;2m\]]\[\e[0;1;38;5;105m\][\[\e[0;1;38;5;202m\]\!\[\e[0;1;38;5;105m\]]\[\e[0;1;2;38;5;160m\]\u\[\e[0;1;38;5;214m\]@\[\e[0;1;38;5;68m\]\h\[\e[0;1m\]:\[\e[0;2m\]\w\[\e[0;1m\][\[\e[0;1m\]$?\[\e[0;1m\]]\[\e[0;1;2m\]\$ \[\e[0m\]'
        else
#! USER = GREEN
			PS1='\[\e[0;1;2m\][\[\e[0;1;2;4m\]\A\[\e[0;1;2m\]]\[\e[0;1;38;5;105m\][\[\e[0;1;38;5;202m\]\!\[\e[0;1;38;5;105m\]]\[\e[0;1;2;38;5;112m\]\u\[\e[0;1;38;5;214m\]@\[\e[0;1;38;5;68m\]\h\[\e[0;1m\]:\[\e[0;2m\]\w\[\e[0;1m\][\[\e[0;1m\]$?\[\e[0;1m\]]\[\e[0;1;2m\]\$ \[\e[0m\]'
    fi
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
#! Раскоментировали алиасы чтобы выводился цветной вывод результатов комманд.
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#! Раскоментировали для цветного синтаксиса. 
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
#! Добавляем полезный алиас который выводит списком файлы и папки в директории. 
alias lsa='ls -Alh'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

#-------------------------------------------------------------------------------------------
#! Автоматически подключаться к сессии TMUX при входе на SSH либо создавать и подключаться. 
# Autostart TMUX under SSH
if [[ -z $TMUX && -n $SSH_TTY ]]; then
    me=$(whoami)
    real_tmux=$(command -v tmux)

    if [ -z $real_tmux ]; then
        echo "No tmux installed."
    fi

    export TERM="xterm-256color"

    if $real_tmux has-session -t $me 2>/dev/null; then
        $real_tmux attach-session -t $me
    else
        if [[ -n $SSH_TTY ]]; then
            (tmux new-session -d -s $me && tmux attach-session -t $me)
        fi
    fi
fi
# Tmux start alias
#! Запуск TMUX сразу с необходимыми параметрами.
#! Если есть сессия от имени текущего пользователя тогда подключится к ней.
#! Если сессии нет, создать и подключится. 
tmux_run() {
    me=$(whoami)
    real_tmux=$(which tmux)
    args_num="$#"

    export TERM="xterm-256color"

    if [ "$#" -gt 0 ]; then
        $real_tmux "$*"
    else
        if [[ ! -z $TMUX ]]; then
            $real_tmux
        else
            if $real_tmux has-session -t $me 2>/dev/null; then
                $real_tmux attach-session -t $me
            else
                $real_tmux new -s $USER
                $real_tmux attach-session -t $me
            fi
        fi
    fi
}
alias tmux="tmux_run"
#-------------------------------------------------------------------------------------------
