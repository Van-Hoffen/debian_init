#!/bin/bash

# Скрипт для первичной инициализации системы на базе Debian под стандарты системного администратора и DevOps специалиста

set -e  # Прерывать выполнение при ошибках

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Начинаем первичную инициализацию системы Debian для системного администратора и DevOps специалиста${NC}"

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

# Установка базовых пакетов для системного администратора и DevOps специалиста
log_info "Устанавливаем базовые пакеты..."
BASE_PACKAGES=(
    "sudo"
    "curl"
    "ncdu"
    "mc"
    "lm-sensors"
    "strace"
    "htop"
    "nload"
    "tmux"
    "docker.io"
    "docker-compose"
    "zabbix-agent"
    "git"
    "fzf"
    "apt-transport-https"
    "ca-certificates"
    "gnupg"
    "lsb-release"
    "unzip"
    "zip"
    "build-essential"
    "wget"
    "zsh"
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

# Выбор оболочки (zsh или bash)
log_info "Выберите предпочитаемую оболочку:"
echo "1) zsh"
echo "2) bash"
read -p "Введите номер (1 или 2): " shell_choice

if [[ "$shell_choice" == "1" ]]; then
    # Установка zsh как основной оболочки
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
else
    log_info "Выбрана оболочка bash, пропускаем установку zsh"
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

# Алиасы для системного администрирования
alias top='htop'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'
alias netstat='netstat -tuln'
alias ncdu='ncdu --color dark'
alias mc='mc -b'

# Алиасы для работы с Docker и Docker Compose
if command -v docker &> /dev/null; then
    alias dps='docker ps'
    alias di='docker images'
    alias dsys='docker system prune -f'
    alias dvol='docker volume ls'
    alias dnet='docker network ls'
fi

if command -v docker-compose &> /dev/null; then
    alias dc='docker-compose'
    alias dcp='docker-compose ps'
    alias dcl='docker-compose logs -f'
    alias dcu='docker-compose up -d'
    alias dcd='docker-compose down'
fi

# Алиасы для работы с Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gb='git branch'
alias gd='git diff'

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

# Добавление настроек для fzf в bashrc и zshrc
if grep -q 'fzf' ~/.bashrc; then
    log_info "Настройки fzf уже присутствуют в ~/.bashrc"
else
    echo "" >> ~/.bashrc
    echo "# FZF settings" >> ~/.bashrc
    echo "[ -f ~/.fzf.bash ] && source ~/.fzf.bash" >> ~/.bashrc
    log_info "Настройки fzf добавлены в ~/.bashrc"
fi

# Добавление настроек для fzf в zshrc если используется zsh
if [[ "$shell_choice" == "1" ]] && [ -f ~/.zshrc ]; then
    if grep -q 'fzf' ~/.zshrc; then
        log_info "Настройки fzf уже присутствуют в ~/.zshrc"
    else
        echo "" >> ~/.zshrc
        echo "# FZF settings" >> ~/.zshrc
        echo "[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh" >> ~/.zshrc
        log_info "Настройки fzf добавлены в ~/.zshrc"
    fi
fi

# Создание директорий для работы
log_info "Создаем стандартные директории..."
mkdir -p ~/Projects ~/Documents ~/Downloads ~/Temp ~/Scripts

# Создание директории для Docker Compose файлов в /opt (для системного администратора)
if [ "$EUID" -eq 0 ] || [ -w /opt ]; then
    sudo mkdir -p /opt/docker-compose
    log_info "Создана директория /opt/docker-compose для размещения docker-compose.yaml файлов"
else
    log_warn "Нет прав для создания директории в /opt, создаем в домашней директории"
    mkdir -p ~/docker-compose
    log_info "Создана директория ~/docker-compose для размещения docker-compose.yaml файлов"
fi

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
    
    git config --global core.editor "mc"
    git config --global merge.tool "mc"
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

# Добавление текущего пользователя в группу docker (если пакет docker.io установлен)
if command -v docker &> /dev/null; then
    sudo usermod -aG docker $USER
    log_info "Пользователь добавлен в группу docker"
else
    log_warn "Docker не установлен"
fi

log_info "Первичная инициализация системы завершена!"
log_info "Установлены инструменты для системного администрирования и DevOps:"
log_info "  - Мониторинг: htop, nload, ncdu, lm-sensors"
log_info "  - Управление файлами: mc, zip, unzip"
log_info "  - Сеть: curl, nc"
log_info "  - Отладка: strace"
log_info "  - Docker и Docker Compose"
log_info "  - Zabbix agent для мониторинга"
log_info "  - Git и сопутствующие инструменты"
log_info "  - Fuzzy finder (fzf) для удобства навигации"
log_info ""
log_info "Рекомендуется перезапустить сессию или выполнить 'source ~/.bashrc' (или ~/.zshrc при использовании zsh) для применения всех изменений."
log_info "Docker Compose файлы рекомендуется размещать в директории /opt/docker-compose"