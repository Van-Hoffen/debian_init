# Debian Setup Script

Этот репозиторий содержит скрипт для первичной инициализации системы на базе Debian под стандарты пользователя.

## Содержание

- `debian_setup.sh` - основной скрипт инициализации
- `bashrc` - настройки bash
- `tmux.conf` - настройки tmux

## Что делает скрипт

1. Обновляет систему
2. Устанавливает базовые пакеты:
   - curl, wget
   - git, vim, tmux
   - build-essential
   - zsh
   - htop, tree
   - unzip, zip
   - mc, neofetch
   - software-properties-common
   - apt-transport-https, ca-certificates, gnupg, lsb-release

3. Копирует пользовательские настройки:
   - bashrc
   - tmux.conf

4. Устанавливает и настраивает zsh:
   - Устанавливает oh-my-zsh
   - Устанавливает тему powerlevel10k
   - Устанавливает плагины zsh-syntax-highlighting и zsh-autosuggestions

5. Добавляет полезные алиасы в ~/.bash_aliases

6. Устанавливает fzf (fuzzy finder)

7. Создает стандартные директории:
   - ~/Projects
   - ~/Documents
   - ~/Downloads
   - ~/Temp
   - ~/Scripts

8. Настраивает Git (запрашивает имя и email)

9. Устанавливает nvm и Node.js

10. Устанавливает Python инструменты

11. Устанавливает Docker

## Использование

1. Склонируйте репозиторий:
   ```bash
   git clone https://github.com/Van-Hoffen/debian_init
   cd debian-setup
   ```

2. Запустите скрипт:
   ```bash
   chmod +x debian_setup.sh
   ./debian_setup.sh
   ```

## Важно

- Скрипт использует sudo для установки пакетов
- Рекомендуется запускать скрипт под обычным пользователем, а не root
- После выполнения скрипта рекомендуется перезапустить сессию или выполнить `source ~/.bashrc`

## Лицензия

GPLv3
