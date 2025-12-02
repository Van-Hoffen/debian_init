#!/bin/bash

# Скрипт для первичной инициализации системы на базе Debian под стандарты пользователя

set -e  # Прерывать выполнение при ошибках

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Начинаем первичную инициализацию системы Debian${NC}"

# Функция для вывода сообщений
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка на root
if [[ $EUID -eq 0 ]]; then
   log_warn "Скрипт запущен с root правами. Это может быть небезопасно. Продолжить? (y/N)"
   read -r response
   if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
       exit 0
   fi
else
   log_info "Скрипт будет использовать sudo для выполнения команд с правами root"
fi

# Обновление системы
log_info "Обновляем список пакетов..."
sudo apt update

log_info "Обновляем систему..."
sudo apt upgrade -y

# Установка базовых пакетов
log_info "Устанавливаем базовые пакеты..."
BASE_PACKAGES=(
    "curl"
    "wget"
    "git"
    "vim"
    "tmux"
    "build-essential"
    "zsh"
    "htop"
    "tree"
    "unzip"
    "zip"
    "mc"
    "neofetch"
    "software-properties-common"
    "apt-transport-https"
    "ca-certificates"
    "gnupg"
    "lsb-release"
)

for package in "${BASE_PACKAGES[@]}"; do
    log_info "Устанавливаем $package..."
    sudo apt install -y "$package"
done

# Копирование настроек bash
log_info "Копируем настройки bash..."
if [ -f "/workspace/bashrc" ]; then
    cp /workspace/bashrc ~/.bashrc
    log_info "Файл ~/.bashrc обновлён из /workspace/bashrc"
else
    log_warn "Файл /workspace/bashrc не найден"
fi

# Копирование настроек tmux
log_info "Копируем настройки tmux..."
if [ -f "/workspace/tmux.conf" ]; then
    cp /workspace/tmux.conf ~/.tmux.conf
    log_info "Файл ~/.tmux.conf обновлён из /workspace/tmux.conf"
else
    log_warn "Файл /workspace/tmux.conf не найден"
fi

# Установка zsh как основной оболочки (если пользователь хочет)
log_info "Устанавливаем zsh как основную оболочку..."
if command -v zsh &> /dev/null; then
    chsh -s "$(which zsh)"
    log_info "zsh установлена как основная оболочка"
else
    log_warn "zsh не найдена"
fi

# Установка oh-my-zsh (если пользователь хочет)
log_info "Устанавливаем oh-my-zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_info "oh-my-zsh установлена"
else
    log_warn "oh-my-zsh уже установлена"
fi

# Установка powerlevel10k темы для zsh
log_info "Устанавливаем тему powerlevel10k для zsh..."
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    log_info "Тема powerlevel10k установлена"
else
    log_warn "Тема powerlevel10k уже установлена"
fi

# Установка плагинов для zsh
log_info "Устанавливаем плагины для zsh..."
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    log_info "Плагин zsh-syntax-highlighting установлен"
fi

if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    log_info "Плагин zsh-autosuggestions установлен"
fi

# Создание ~/.bash_aliases если не существует
if [ ! -f ~/.bash_aliases ]; then
    touch ~/.bash_aliases
    log_info "Файл ~/.bash_aliases создан"
fi

# Добавление дополнительных алиасов в ~/.bash_aliases
cat >> ~/.bash_aliases << 'EOF'

# Дополнительные алиасы
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'
alias autoremove='sudo apt autoremove -y'
alias clean='sudo apt clean'

# Алиасы для работы с архивами
alias untar='tar -zxvf'
alias zipf='zip -r'

# Алиасы для работы с Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gb='git branch'
alias gd='git diff'

# Алиасы для работы с Docker (если установлен)
if command -v docker &> /dev/null; then
    alias dps='docker ps'
    alias di='docker images'
fi

EOF

log_info "Дополнительные алиасы добавлены в ~/.bash_aliases"

# Установка утилиты fzf (fuzzy finder)
log_info "Устанавливаем fzf..."
if [ ! -d "$HOME/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
    log_info "fzf установлена"
else
    log_warn "fzf уже установлена"
fi

# Добавление настроек для fzf в bashrc
if grep -q 'fzf' ~/.bashrc; then
    log_info "Настройки fzf уже присутствуют в ~/.bashrc"
else
    echo "" >> ~/.bashrc
    echo "# FZF settings" >> ~/.bashrc
    echo "[ -f ~/.fzf.bash ] && source ~/.fzf.bash" >> ~/.bashrc
    log_info "Настройки fzf добавлены в ~/.bashrc"
fi

# Создание директорий для работы
log_info "Создаем стандартные директории..."
mkdir -p ~/Projects ~/Documents ~/Downloads ~/Temp ~/Scripts

# Установка настроек git (если git установлен)
if command -v git &> /dev/null; then
    log_info "Настраиваем Git..."
    
    # Проверка, были ли уже установлены настройки
    if ! git config --global user.name &> /dev/null; then
        log_info "Введите ваше имя для Git:"
        read -r git_name
        git config --global user.name "$git_name"
    fi
    
    if ! git config --global user.email &> /dev/null; then
        log_info "Введите ваш email для Git:"
        read -r git_email
        git config --global user.email "$git_email"
    fi
    
    git config --global core.editor "vim"
    git config --global merge.tool "vimdiff"
    git config --global push.default "simple"
    log_info "Git настроен"
fi

# Настройка SSH если директория существует
if [ -d ~/.ssh ]; then
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/id_*
    chmod 644 ~/.ssh/*.pub
    log_info "Права доступа к SSH ключам установлены"
fi

# Установка Node.js через nvm (опционально)
log_info "Устанавливаем nvm и Node.js..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Установка последней LTS версии Node.js
if command -v nvm &> /dev/null; then
    nvm install --lts
    nvm use --lts
    log_info "Node.js LTS установлен через nvm"
else
    log_warn "nvm не установлена, пропускаем установку Node.js"
fi

# Установка Python инструментов (если Python установлен)
if command -v python3 &> /dev/null; then
    log_info "Устанавливаем Python инструменты..."
    sudo apt install -y python3-pip python3-dev
    pip3 install --user --upgrade pip
    log_info "Python инструменты установлены"
fi

# Установка Docker (опционально)
log_info "Устанавливаем Docker..."
if ! command -v docker &> /dev/null; then
    # Добавление официального GPG ключа Docker
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Установка репозитория Docker
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Добавление текущего пользователя в группу docker
    sudo usermod -aG docker $USER
    
    log_info "Docker установлен и пользователь добавлен в группу docker"
else
    log_warn "Docker уже установлен"
fi

# Функция для переименования файлов/директорий с запросом у пользователя
rename_function() {
    log_info "Хотите выполнить переименование каких-либо файлов или директорий? (y/N)"
    read -r rename_response
    if [[ "$rename_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Введите путь к файлу или директории, которую нужно переименовать:"
        read -r source_path
        if [ -e "$source_path" ]; then
            log_info "Введите новое имя:"
            read -r new_name
            dir_path=$(dirname "$source_path")
            if [ "$dir_path" = "." ]; then
                dir_path=""
            else
                dir_path="$dir_path/"
            fi
            new_path="${dir_path}${new_name}"
            
            log_info "Переименовываем '$source_path' в '$new_path'"
            mv "$source_path" "$new_path"
            log_info "Переименование выполнено успешно!"
        else
            log_error "Файл или директория '$source_path' не найдена!"
        fi
    else
        log_info "Пропускаем переименование."
    fi
}

# Вызов функции переименования
rename_function

log_info "Первичная инициализация системы завершена!"
log_info "Рекомендуется перезапустить сессию или выполнить 'source ~/.bashrc' для применения всех изменений."