import React, { useState } from 'react';
import { Terminal, Code2, Zap, Layers, Server, FileCode, ExternalLink, ShieldCheck, Heart } from 'lucide-react';
import { MOTDViewer } from './components/MOTDViewer';
import { ScriptGenerator } from './components/ScriptGenerator';
import { BashAliasesExplorer } from './components/BashAliasesExplorer';
import { TmuxStudio } from './components/TmuxStudio';
import { ServicesManager } from './components/ServicesManager';
import { DotfilesViewer } from './components/DotfilesViewer';
import { INITIAL_SERVICES, LOGO_1, LOGO_2, LOGO_3 } from './data/dotfiles';

export const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'motd' | 'generator' | 'aliases' | 'tmux' | 'services' | 'dotfiles'>('motd');

  // Shared state between Services and MOTD
  const [services, setServices] = useState(INITIAL_SERVICES);
  const [serverInfoText, setServerInfoText] = useState(
    'Сервер предназначен для инфраструктурных задач и веб-сервисов. Настроен по стандартам Van-Hoffen/debian_init. Ответственный администратор: vhgunner@gmail.com'
  );

  const toggleService = (name: string) => {
    setServices(prev =>
      prev.map(s => (s.name === name ? { ...s, defaultActive: !s.defaultActive } : s))
    );
  };

  // Raw file tree content from repository
  const repoFiles = [
    {
      path: 'root/debian_setup.sh',
      category: 'Setup Script',
      description: 'Основной bash скрипт начальной инициализации Debian сервера',
      content: `#!/bin/bash
# Скрипт для первичной инициализации системы на базе Debian под стандарты пользователя
set -e

RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
NC='\\033[0m'

echo -e "\${GREEN}Начинаем первичную инициализацию системы Debian\${NC}"

log_info()  { echo -e "\${GREEN}[INFO]\${NC} \$1"; }
log_warn()  { echo -e "\${YELLOW}[WARN]\${NC} \$1"; }
log_error() { echo -e "\${RED}[ERROR]\${NC} \$1"; }

if [[ $EUID -eq 0 ]]; then
   log_warn "Скрипт запущен с root правами."
fi

log_info "Обновляем список пакетов..."
sudo apt update
sudo apt upgrade -y

BASE_PACKAGES=(
    "curl" "wget" "git" "vim" "tmux" "build-essential" "zsh" "htop" "tree"
    "unzip" "zip" "mc" "neofetch" "software-properties-common" "apt-transport-https"
    "ca-certificates" "gnupg" "lsb-release"
)
for package in "\${BASE_PACKAGES[@]}"; do
    sudo apt install -y "$package"
done

# Копирование настроек bash и tmux
[ -f "/workspace/bashrc" ] && cp /workspace/bashrc ~/.bashrc
[ -f "/workspace/tmux.conf" ] && cp /workspace/tmux.conf ~/.tmux.conf

mkdir -p ~/Projects ~/Documents ~/Downloads ~/Temp ~/Scripts
log_info "Первичная инициализация системы завершена!"`,
    },
    {
      path: 'etc/bash/.bash_welcome',
      category: 'MOTD Script',
      description: 'Функция welcome_screen() с ASCII-лого, мониторингом CPU, RAM, дисков и сервисов',
      content: `# /etc/bash/.bash_welcome
# Подключается из ~/.bashrc: if [ -f /etc/bash/.bash_welcome ]; then . /etc/bash/.bash_welcome; fi
# Вызов: welcome_screen

welcome_screen() {
R='\\e[0;1;38;5;160m'    # Красный
G='\\e[0;1;38;5;112m'    # Зелёный
Y='\\e[0;1;38;5;214m'    # Жёлтый
B='\\e[0;1;38;5;68m'     # Синий
W='\\e[0;1m'             # Белый жирный
D='\\e[0;2m'             # Серый
N='\\e[0m'               # Сброс

# Чтение сервисов из .services_check
mapfile -t SERVICES_CHECK < <(sed 's/#.*//; s/[[:space:]]//g; /^$/d' /etc/bash/.services_check)

# ASCII логотип по IP
current_ip=$(ip -4 addr show scope global | grep -oP '(?<=inet )\\d+\\.\\d+' | head -1)
# Вывод Host, Kernel, Uptime, Network, CPU, RAM/Swap bar, Disks, Sessions, Services, Mail, Server info
}`,
    },
    {
      path: 'etc/bash/.bash_aliases',
      category: 'Bash Aliases',
      description: '40+ псевдонимов и утилит (extract, bak, ff, ips, chkport, genpass, cputop, memtop)',
      content: `# ~/.bash_aliases
# Навигация
alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd ~'
alias lsa='ls -alh'

# Файлы
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'
alias mkdir='mkdir -pv'
alias df='df -h'
alias free='free -h'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me'
alias update='sudo apt update && sudo apt upgrade -y'

# Функции
extract() {
    case "$1" in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz)  tar xzf "$1" ;;
        *.zip)     unzip "$1"   ;;
        *.7z)      7z x "$1"    ;;
        *) echo "Неизвестный формат '$1'" ;;
    esac
}

bak() { cp "$1" "$1.$(date +%F).bak"; }
ff()  { find . -name "*$1*" 2>/dev/null; }
genpass() { tr -dc 'A-Za-z0-9!@#$%' </dev/urandom | head -c "\${1:-16}"; echo; }`,
    },
    {
      path: 'root/.tmux.conf',
      category: 'Tmux Config',
      description: 'Двухуровневый статус-бар, TrueColor, Alt+1..9, popup hotkeys cheatsheet, sync-panes',
      content: `# ~/.tmux.conf
set -g default-terminal "xterm-256color"
set -ga terminal-overrides ",xterm-256color:Tc"
set -g history-limit 10000
set -g base-index 1
set -g pane-base-index 1
set -g renumber-windows on
set -g mouse on

# Префикс: Ctrl+a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Разделение панелей
bind = split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Быстрое переключение окон Alt+1-9
bind -n M-1 run-shell "tmux select-window -t 1 2>/dev/null || tmux new-window -t 1"
bind -n M-2 run-shell "tmux select-window -t 2 2>/dev/null || tmux new-window -t 2"

# Синхронизация ввода
bind S setw synchronize-panes

# Двухуровневая статусная строка
set -g status 2
set -g status-left '#{?#{==:#{client_user},root},#[bg=colour160 fg=colour255 bold] ROOT:#S ,#[bg=colour66 fg=colour234 bold] #S }'`,
    },
    {
      path: 'root/apply-user-dotfiles.sh',
      category: 'Management Script',
      description: 'Копирование dotfiles пользователям с нумерованными бэкапами и chown',
      content: `#!/usr/bin/env bash
# apply-user-dotfiles.sh
# Копирует .bashrc и .tmux.conf во все домашние каталоги с нумерованным бэкапом
set -euo pipefail
DRY_RUN=false
[[ "\${1:-}" == "--dry-run" ]] && DRY_RUN=true
DOTFILES=("/root/.bashrc" "/root/.tmux.conf")`,
    },
    {
      path: 'root/apt_install_vm.sh',
      category: 'Package Script',
      description: 'Быстрая установка пакетов для виртуальных машин',
      content: `apt-get update
apt-get dist-upgrade -y
apt-get install sudo mutt curl ncdu mc htop nload tmux zabbix-agent2 git fzf ca-certificates gnupg lsb-release unzip zip build-essential wget net-tools fastfetch procps -y`,
    },
    {
      path: 'root/apt_install_hw.sh',
      category: 'Package Script',
      description: 'Установка пакетов для физических серверов с датчиками lm-sensors',
      content: `apt-get update
apt-get dist-upgrade -y
apt-get install sudo mutt curl ncdu mc lm-sensors strace htop nload tmux zabbix-agent2 git fzf ca-certificates gnupg lsb-release unzip zip build-essential wget net-tools fastfetch procps -y`,
    },
  ];

  return (
    <div className="min-h-screen bg-[#0b0f17] text-gray-200 flex flex-col font-sans selection:bg-teal-700 selection:text-white">
      {/* Top Navbar */}
      <header className="bg-[#121620] border-b border-gray-800 sticky top-0 z-40 backdrop-blur-md">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-red-600 via-rose-600 to-amber-600 flex items-center justify-center shadow-lg shadow-red-950/40 text-white font-bold text-lg">
              🐧
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="font-bold text-sm tracking-tight text-white">
                  Debian Init
                </h1>
                <span className="text-[10px] font-mono bg-teal-500/20 text-teal-300 border border-teal-500/30 px-2 py-0.5 rounded-full font-semibold">
                  SysAdmin Studio
                </span>
              </div>
              <p className="text-[11px] text-gray-400 font-mono">
                Van-Hoffen / debian_init
              </p>
            </div>
          </div>

          {/* Navigation Tabs */}
          <nav className="hidden md:flex items-center space-x-1">
            <button
              onClick={() => setActiveTab('motd')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                activeTab === 'motd'
                  ? 'bg-emerald-600/20 text-emerald-300 border border-emerald-500/40'
                  : 'text-gray-400 hover:text-gray-200 hover:bg-gray-800/60'
              }`}
            >
              <Terminal className="w-3.5 h-3.5" />
              <span>MOTD Terminal</span>
            </button>

            <button
              onClick={() => setActiveTab('generator')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                activeTab === 'generator'
                  ? 'bg-blue-600/20 text-blue-300 border border-blue-500/40'
                  : 'text-gray-400 hover:text-gray-200 hover:bg-gray-800/60'
              }`}
            >
              <Code2 className="w-3.5 h-3.5" />
              <span>Setup Script Generator</span>
            </button>

            <button
              onClick={() => setActiveTab('aliases')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                activeTab === 'aliases'
                  ? 'bg-purple-600/20 text-purple-300 border border-purple-500/40'
                  : 'text-gray-400 hover:text-gray-200 hover:bg-gray-800/60'
              }`}
            >
              <Zap className="w-3.5 h-3.5" />
              <span>Aliases & Utilities</span>
            </button>

            <button
              onClick={() => setActiveTab('tmux')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                activeTab === 'tmux'
                  ? 'bg-teal-600/20 text-teal-300 border border-teal-500/40'
                  : 'text-gray-400 hover:text-gray-200 hover:bg-gray-800/60'
              }`}
            >
              <Layers className="w-3.5 h-3.5" />
              <span>Tmux Studio</span>
            </button>

            <button
              onClick={() => setActiveTab('services')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                activeTab === 'services'
                  ? 'bg-amber-600/20 text-amber-300 border border-amber-500/40'
                  : 'text-gray-400 hover:text-gray-200 hover:bg-gray-800/60'
              }`}
            >
              <Server className="w-3.5 h-3.5" />
              <span>Services (.services_check)</span>
            </button>

            <button
              onClick={() => setActiveTab('dotfiles')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                activeTab === 'dotfiles'
                  ? 'bg-rose-600/20 text-rose-300 border border-rose-500/40'
                  : 'text-gray-400 hover:text-gray-200 hover:bg-gray-800/60'
              }`}
            >
              <FileCode className="w-3.5 h-3.5" />
              <span>Dotfiles Source</span>
            </button>
          </nav>

          {/* External Github Link */}
          <div className="flex items-center space-x-2">
            <a
              href="https://github.com/Van-Hoffen/debian_init"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-800/80 hover:bg-gray-700 text-gray-300 rounded-lg text-xs font-medium border border-gray-700 transition-colors"
            >
              <svg className="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24">
                <path fillRule="evenodd" clipRule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.53 1.032 1.53 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" />
              </svg>
              <span className="hidden sm:inline">GitHub Репозиторий</span>
              <ExternalLink className="w-3 h-3 text-gray-400" />
            </a>
          </div>
        </div>

        {/* Mobile Navigation Row */}
        <div className="flex md:hidden overflow-x-auto px-4 py-2 border-t border-gray-800 gap-1.5">
          <button
            onClick={() => setActiveTab('motd')}
            className={`px-2.5 py-1 rounded text-xs shrink-0 ${activeTab === 'motd' ? 'bg-emerald-600 text-white' : 'text-gray-400'}`}
          >
            MOTD Terminal
          </button>
          <button
            onClick={() => setActiveTab('generator')}
            className={`px-2.5 py-1 rounded text-xs shrink-0 ${activeTab === 'generator' ? 'bg-blue-600 text-white' : 'text-gray-400'}`}
          >
            Generator
          </button>
          <button
            onClick={() => setActiveTab('aliases')}
            className={`px-2.5 py-1 rounded text-xs shrink-0 ${activeTab === 'aliases' ? 'bg-purple-600 text-white' : 'text-gray-400'}`}
          >
            Aliases
          </button>
          <button
            onClick={() => setActiveTab('tmux')}
            className={`px-2.5 py-1 rounded text-xs shrink-0 ${activeTab === 'tmux' ? 'bg-teal-600 text-white' : 'text-gray-400'}`}
          >
            Tmux
          </button>
          <button
            onClick={() => setActiveTab('services')}
            className={`px-2.5 py-1 rounded text-xs shrink-0 ${activeTab === 'services' ? 'bg-amber-600 text-white' : 'text-gray-400'}`}
          >
            Services
          </button>
          <button
            onClick={() => setActiveTab('dotfiles')}
            className={`px-2.5 py-1 rounded text-xs shrink-0 ${activeTab === 'dotfiles' ? 'bg-rose-600 text-white' : 'text-gray-400'}`}
          >
            Dotfiles
          </button>
        </div>
      </header>

      {/* Main Content Viewport */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {activeTab === 'motd' && (
          <MOTDViewer serverInfoText={serverInfoText} services={services} />
        )}
        {activeTab === 'generator' && <ScriptGenerator />}
        {activeTab === 'aliases' && <BashAliasesExplorer />}
        {activeTab === 'tmux' && <TmuxStudio />}
        {activeTab === 'services' && (
          <ServicesManager
            services={services}
            onToggleService={toggleService}
            serverInfoText={serverInfoText}
            onUpdateServerInfo={setServerInfoText}
          />
        )}
        {activeTab === 'dotfiles' && <DotfilesViewer files={repoFiles} />}
      </main>

      {/* Footer */}
      <footer className="border-t border-gray-800 bg-[#0d1117] py-4 text-xs text-gray-500 font-mono text-center">
        <div className="max-w-7xl mx-auto px-4 flex flex-col sm:flex-row items-center justify-between gap-2">
          <span>Debian Init Toolkit — Van-Hoffen/debian_init (GPLv3)</span>
          <span className="text-gray-600">Клиентское SPA-приложение для администрирования серверов</span>
        </div>
      </footer>
    </div>
  );
};
