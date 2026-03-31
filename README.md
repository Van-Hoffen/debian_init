# Debian Setup Script

Этот репозиторий содержит скрипт для первичной инициализации системы на базе Debian под стандарты системного администратора и DevOps специалиста.

## Содержание

- `debian_setup.sh` - основной скрипт инициализации
- `bashrc` - настройки bash
- `tmux.conf` - настройки tmux

## Что делает скрипт

1. Обновляет систему
2. Устанавливает базовые пакеты для системного администрирования и DevOps:
   - sudo, curl, wget
   - ncdu, mc, lm-sensors, strace
   - htop, nload
   - tmux
   - docker.io, docker-compose
   - zabbix-agent
   - git, fzf
   - apt-transport-https, ca-certificates, gnupg, lsb-release
   - unzip, zip
   - build-essential
   - zsh

3. Копирует пользовательские настройки:
   - bashrc
   - tmux.conf

4. Предоставляет выбор оболочки (zsh или bash):
   - При выборе zsh:
     * Устанавливает oh-my-zsh
     * Устанавливает тему powerlevel10k
     * Устанавливает плагины zsh-syntax-highlighting и zsh-autosuggestions
   - При выборе bash: пропускает установку zsh

5. Добавляет полезные алиасы в ~/.bash_aliases:
   - Для управления пакетами (update, install, remove и др.)
   - Для работы с архивами (untar, zipf)
   - Для системного администрирования (top, df, du, free и др.)
   - Для работы с Docker и Docker Compose (dps, di, dc, dcp и др.)
   - Для работы с Git (gs, ga, gc, gp и др.)

6. Устанавливает fzf (fuzzy finder)

7. Создает стандартные директории:
   - ~/Projects
   - ~/Documents
   - ~/Downloads
   - ~/Temp
   - ~/Scripts
   - /opt/docker-compose (для размещения файлов docker-compose.yaml)

8. Настраивает Git (запрашивает имя и email, использует mc как редактор)

9. Устанавливает nvm и Node.js

10. Устанавливает Python инструменты

11. Добавляет текущего пользователя в группу docker

## Использование

1. Склонируйте репозиторий:
   ```bash
   git clone https://github.com/Van-Hoffen/debian_init /
   cd debian-setup
   ```

2. Запустите скрипт:
   ```bash
   chmod +x debian_setup.sh /
   ./debian_setup.sh
   ```

## Важно

- Скрипт использует sudo для установки пакетов
- Рекомендуется запускать скрипт под обычным пользователем, а не root
- После выполнения скрипта рекомендуется перезапустить сессию или выполнить `source ~/.bashrc`

## Лицензия

GPLv3
