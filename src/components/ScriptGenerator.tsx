import React, { useState } from 'react';
import { Terminal, Download, Copy, Check, Sliders, Shield, Code2, Server, Folder, Sparkles, Layers } from 'lucide-react';

export const ScriptGenerator: React.FC = () => {
  // Preset types
  const [preset, setPreset] = useState<'debian_setup' | 'apt_install_vm' | 'apt_install_hw' | 'custom'>('debian_setup');

  // Configuration options
  const [updateUpgrade, setUpdateUpgrade] = useState(true);
  const [basePackages, setBasePackages] = useState(true);
  const [includeTmuxDotfiles, setIncludeTmuxDotfiles] = useState(true);
  const [includeBashrcDotfiles, setIncludeBashrcDotfiles] = useState(true);
  const [installZsh, setInstallZsh] = useState(true);
  const [installOhMyZsh, setInstallOhMyZsh] = useState(true);
  const [installP10k, setInstallP10k] = useState(true);
  const [installZshPlugins, setInstallZshPlugins] = useState(true);
  const [installFzf, setInstallFzf] = useState(true);
  const [createDirs, setCreateDirs] = useState(true);
  
  // Dev stacks
  const [configureGit, setConfigureGit] = useState(true);
  const [gitName, setGitName] = useState('DevOps Engineer');
  const [gitEmail, setGitEmail] = useState('admin@example.com');
  const [installNodeNvm, setInstallNodeNvm] = useState(true);
  const [installPython, setInstallPython] = useState(true);
  const [installDocker, setInstallDocker] = useState(true);
  const [hardwareSensors, setHardwareSensors] = useState(false);
  const [applyUserDotfiles, setApplyUserDotfiles] = useState(true);

  const [copied, setCopied] = useState(false);
  const [copiedCurl, setCopiedCurl] = useState(false);

  // Apply presets
  const handlePresetChange = (selected: 'debian_setup' | 'apt_install_vm' | 'apt_install_hw' | 'custom') => {
    setPreset(selected);
    if (selected === 'apt_install_vm') {
      setUpdateUpgrade(true);
      setBasePackages(true);
      setHardwareSensors(false);
      setInstallZsh(false);
      setInstallNodeNvm(false);
      setInstallPython(false);
      setInstallDocker(false);
    } else if (selected === 'apt_install_hw') {
      setUpdateUpgrade(true);
      setBasePackages(true);
      setHardwareSensors(true);
      setInstallZsh(false);
      setInstallNodeNvm(false);
      setInstallPython(false);
      setInstallDocker(false);
    } else if (selected === 'debian_setup') {
      setUpdateUpgrade(true);
      setBasePackages(true);
      setIncludeTmuxDotfiles(true);
      setIncludeBashrcDotfiles(true);
      setInstallZsh(true);
      setInstallOhMyZsh(true);
      setInstallP10k(true);
      setInstallZshPlugins(true);
      setInstallFzf(true);
      setCreateDirs(true);
      setConfigureGit(true);
      setInstallNodeNvm(true);
      setInstallPython(true);
      setInstallDocker(true);
    }
  };

  // Generate Shell Script content based on active state
  const generateScript = () => {
    if (preset === 'apt_install_vm') {
      return `#!/bin/bash
# =============================================================================
# apt_install_vm.sh - Быстрая установка пакетов для виртуальной машины
# Репозиторий: Van-Hoffen/debian_init
# =============================================================================
set -e

apt-get update
apt-get dist-upgrade -y
apt-get install sudo mutt curl ncdu mc htop nload tmux zabbix-agent2 git fzf ca-certificates gnupg lsb-release unzip zip build-essential wget net-tools fastfetch procps -y

echo "Установка пакетов для VM завершена успешно!"`;
    }

    if (preset === 'apt_install_hw') {
      return `#!/bin/bash
# =============================================================================
# apt_install_hw.sh - Установка пакетов для физического сервера (Bare-Metal)
# Включает lm-sensors, strace, мониторинг температуры и оборудования
# Репозиторий: Van-Hoffen/debian_init
# =============================================================================
set -e

apt-get update
apt-get dist-upgrade -y
apt-get install sudo mutt curl ncdu mc lm-sensors strace htop nload tmux zabbix-agent2 git fzf ca-certificates gnupg lsb-release unzip zip build-essential wget net-tools fastfetch procps -y

echo "Установка пакетов для физического сервера завершена успешно!"`;
    }

    // Full custom debian_setup.sh
    let script = `#!/bin/bash
# =============================================================================
# debian_setup.sh - Первичная инициализация системы на базе Debian
# Репозиторий: Van-Hoffen/debian_init
# Сгенерировано через Debian Init Web Studio
# =============================================================================
set -e

RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
NC='\\033[0m'

log_info()  { echo -e "\${GREEN}[INFO]\${NC} \$1"; }
log_warn()  { echo -e "\${YELLOW}[WARN]\${NC} \$1"; }
log_error() { echo -e "\${RED}[ERROR]\${NC} \$1"; }

log_info "Начинаем первичную инициализацию системы Debian..."

# Проверка root прав
if [[ $EUID -eq 0 ]]; then
    log_info "Выполнение с правами root."
else
    log_info "Скрипт будет использовать sudo для команд с правами root."
fi
`;

    if (updateUpgrade) {
      script += `
# 1. Обновление системы
log_info "Обновляем список пакетов и систему..."
sudo apt update && sudo apt upgrade -y
`;
    }

    if (basePackages) {
      const extraHw = hardwareSensors ? ' lm-sensors strace' : '';
      script += `
# 2. Установка базовых пакетов
log_info "Устанавливаем базовые утилиты..."
BASE_PACKAGES=(
    curl wget git vim tmux build-essential htop tree unzip zip mc neofetch
    software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    net-tools procps fastfetch ncdu nload${extraHw}
)
for pkg in "\${BASE_PACKAGES[@]}"; do
    sudo apt install -y "$pkg" || log_warn "Не удалось установить $pkg"
done
`;
    }

    if (includeBashrcDotfiles) {
      script += `
# 3. Настройка ~/.bashrc и ~/.bash_aliases
log_info "Развертывание dotfiles bash..."
if [ -f "/etc/bash/.bash_aliases" ]; then
    log_info "Системные алиасы уже подключены в /etc/bash/.bash_aliases"
fi
`;
    }

    if (includeTmuxDotfiles) {
      script += `
# 4. Настройка ~/.tmux.conf
log_info "Развертывание настроек tmux с двухуровневой статусной строкой..."
`;
    }

    if (installZsh) {
      script += `
# 5. Установка и настройка Zsh
log_info "Установка zsh..."
sudo apt install -y zsh
if command -v zsh &>/dev/null; then
    chsh -s "$(which zsh)" "$USER" || true
fi
`;
      if (installOhMyZsh) {
        script += `
# Установка Oh-My-Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
`;
      }
      if (installP10k) {
        script += `
# Установка темы Powerlevel10k
if [ ! -d "\${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
fi
`;
      }
      if (installZshPlugins) {
        script += `
# Установка плагинов zsh-syntax-highlighting & zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-autosuggestions \${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
`;
      }
    }

    if (installFzf) {
      script += `
# 6. Установка fzf (fuzzy finder)
log_info "Устанавливаем fzf..."
if [ ! -d "$HOME/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
fi
`;
    }

    if (createDirs) {
      script += `
# 7. Создание стандартных каталогов пользователя
log_info "Создание структуры рабочих папок..."
mkdir -p ~/Projects ~/Documents ~/Downloads ~/Temp ~/Scripts
`;
    }

    if (configureGit) {
      script += `
# 8. Настройка Git
log_info "Настройка конфигурации Git..."
git config --global user.name "${gitName}"
git config --global user.email "${gitEmail}"
git config --global core.editor "vim"
git config --global merge.tool "vimdiff"
git config --global push.default "simple"
`;
    }

    if (installNodeNvm) {
      script += `
# 9. Установка nvm и Node.js LTS
log_info "Установка Node.js LTS через nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \\. "$NVM_DIR/nvm.sh"
nvm install --lts || true
`;
    }

    if (installPython) {
      script += `
# 10. Установка инструментов Python3
log_info "Установка Python3 и pip..."
sudo apt install -y python3-pip python3-dev
pip3 install --user --upgrade pip || true
`;
    }

    if (installDocker) {
      script += `
# 11. Установка Docker CE и Compose Plugin
log_info "Установка официального репозитория Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker "$USER" || true
log_info "Docker установлен, пользователь $USER добавлен в группу docker"
`;
    }

    if (applyUserDotfiles) {
      script += `
# 12. Распространение dotfiles во все каталоги пользователей
if [ -f "/root/apply-user-dotfiles.sh" ]; then
    sudo bash /root/apply-user-dotfiles.sh || true
fi
`;
    }

    script += `
log_info "=========================================================="
log_info "Первичная инициализация Debian завершена успешно!"
log_info "Выполните 'source ~/.bashrc' или перезайдите в сессию."
`;

    return script;
  };

  const scriptContent = generateScript();

  const copyToClipboard = () => {
    navigator.clipboard.writeText(scriptContent);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const downloadScript = () => {
    const element = document.createElement('a');
    const file = new Blob([scriptContent], { type: 'text/plain' });
    element.href = URL.createObjectURL(file);
    element.download = preset === 'debian_setup' ? 'debian_setup.sh' : `${preset}.sh`;
    document.body.appendChild(element);
    element.click();
    document.body.removeChild(element);
  };

  const curlCommand = 'curl -fsSL https://raw.githubusercontent.com/Van-Hoffen/debian_init/main/root/debian_setup.sh | bash';

  const copyCurl = () => {
    navigator.clipboard.writeText(curlCommand);
    setCopiedCurl(true);
    setTimeout(() => setCopiedCurl(false), 2000);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-[#131923] p-4 rounded-xl border border-gray-800 flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center space-x-3">
          <div className="p-2 bg-blue-500/10 text-blue-400 rounded-lg border border-blue-500/20">
            <Code2 className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-base font-semibold text-white">Setup Script Generator & Customizer</h2>
            <p className="text-xs text-gray-400">
              Генератор скриптов начальной настройки серверов Debian и ALT Linux на основе debian_setup.sh
            </p>
          </div>
        </div>

        {/* Quick One-Liner runner */}
        <div className="flex items-center gap-2 bg-[#0d1117] px-3 py-1.5 rounded-lg border border-gray-700 font-mono text-xs text-gray-300">
          <span className="text-emerald-400 select-none">$</span>
          <span className="truncate max-w-[280px] md:max-w-[420px]">{curlCommand}</span>
          <button
            onClick={copyCurl}
            className="p-1 hover:text-white text-gray-400 transition-colors ml-1"
            title="Копировать команду"
          >
            {copiedCurl ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
          </button>
        </div>
      </div>

      {/* Preset selector bar */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
        <button
          onClick={() => handlePresetChange('debian_setup')}
          className={`p-3 rounded-xl border text-left transition-all ${
            preset === 'debian_setup'
              ? 'bg-emerald-600/15 border-emerald-500/50 text-white'
              : 'bg-[#10151f] border-gray-800 text-gray-400 hover:border-gray-700'
          }`}
        >
          <div className="text-xs font-semibold text-emerald-400">debian_setup.sh</div>
          <div className="text-xs text-gray-300 font-medium mt-0.5">Полная инициализация</div>
          <div className="text-[11px] text-gray-500 mt-1">Dev, Docker, Zsh, Git, Dotfiles</div>
        </button>

        <button
          onClick={() => handlePresetChange('apt_install_vm')}
          className={`p-3 rounded-xl border text-left transition-all ${
            preset === 'apt_install_vm'
              ? 'bg-blue-600/15 border-blue-500/50 text-white'
              : 'bg-[#10151f] border-gray-800 text-gray-400 hover:border-gray-700'
          }`}
        >
          <div className="text-xs font-semibold text-blue-400">apt_install_vm.sh</div>
          <div className="text-xs text-gray-300 font-medium mt-0.5">Для вирт. машин (VM)</div>
          <div className="text-[11px] text-gray-500 mt-1">Легковесный базовый стек</div>
        </button>

        <button
          onClick={() => handlePresetChange('apt_install_hw')}
          className={`p-3 rounded-xl border text-left transition-all ${
            preset === 'apt_install_hw'
              ? 'bg-purple-600/15 border-purple-500/50 text-white'
              : 'bg-[#10151f] border-gray-800 text-gray-400 hover:border-gray-700'
          }`}
        >
          <div className="text-xs font-semibold text-purple-400">apt_install_hw.sh</div>
          <div className="text-xs text-gray-300 font-medium mt-0.5">Bare-Metal (Физический)</div>
          <div className="text-[11px] text-gray-500 mt-1">Включает lm-sensors, strace</div>
        </button>

        <button
          onClick={() => setPreset('custom')}
          className={`p-3 rounded-xl border text-left transition-all ${
            preset === 'custom'
              ? 'bg-amber-600/15 border-amber-500/50 text-white'
              : 'bg-[#10151f] border-gray-800 text-gray-400 hover:border-gray-700'
          }`}
        >
          <div className="text-xs font-semibold text-amber-400">Конструктор</div>
          <div className="text-xs text-gray-300 font-medium mt-0.5">Кастомный стек</div>
          <div className="text-[11px] text-gray-500 mt-1">Тонкая настройка каждого шага</div>
        </button>
      </div>

      {/* Customization checkboxes if custom or debian_setup */}
      <div className="bg-[#10151f] p-5 rounded-xl border border-gray-800 space-y-4">
        <h3 className="text-xs font-semibold uppercase tracking-wider text-gray-400 flex items-center gap-2">
          <Sliders className="w-3.5 h-3.5 text-emerald-400" />
          <span>Конфигурация компонентов инициализации</span>
        </h3>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3 text-xs">
          <label className="flex items-start gap-2.5 p-2.5 bg-gray-900/60 rounded-lg border border-gray-800 hover:border-gray-700 cursor-pointer">
            <input
              type="checkbox"
              checked={updateUpgrade}
              onChange={e => setUpdateUpgrade(e.target.checked)}
              className="mt-0.5 accent-emerald-500"
            />
            <div>
              <div className="font-medium text-gray-200">apt update & upgrade -y</div>
              <div className="text-gray-500 text-[11px]">Обновление индекса пакетов и установленных пакетов</div>
            </div>
          </label>

          <label className="flex items-start gap-2.5 p-2.5 bg-gray-900/60 rounded-lg border border-gray-800 hover:border-gray-700 cursor-pointer">
            <input
              type="checkbox"
              checked={basePackages}
              onChange={e => setBasePackages(e.target.checked)}
              className="mt-0.5 accent-emerald-500"
            />
            <div>
              <div className="font-medium text-gray-200">Базовые пакеты</div>
              <div className="text-gray-500 text-[11px]">curl, wget, vim, tmux, htop, tree, mc, fastfetch</div>
            </div>
          </label>

          <label className="flex items-start gap-2.5 p-2.5 bg-gray-900/60 rounded-lg border border-gray-800 hover:border-gray-700 cursor-pointer">
            <input
              type="checkbox"
              checked={installZsh}
              onChange={e => setInstallZsh(e.target.checked)}
              className="mt-0.5 accent-emerald-500"
            />
            <div>
              <div className="font-medium text-gray-200">Zsh + Oh-My-Zsh + P10k</div>
              <div className="text-gray-500 text-[11px]">Powerlevel10k, zsh-syntax, zsh-autosuggestions</div>
            </div>
          </label>

          <label className="flex items-start gap-2.5 p-2.5 bg-gray-900/60 rounded-lg border border-gray-800 hover:border-gray-700 cursor-pointer">
            <input
              type="checkbox"
              checked={includeTmuxDotfiles}
              onChange={e => setIncludeTmuxDotfiles(e.target.checked)}
              className="mt-0.5 accent-emerald-500"
            />
            <div>
              <div className="font-medium text-gray-200">~/.tmux.conf с двухуровневым статусом</div>
              <div className="text-gray-500 text-[11px]">Цветной ROOT, Alt+1-9, sync-panes, popup cheatsheet</div>
            </div>
          </label>

          <label className="flex items-start gap-2.5 p-2.5 bg-gray-900/60 rounded-lg border border-gray-800 hover:border-gray-700 cursor-pointer">
            <input
              type="checkbox"
              checked={includeBashrcDotfiles}
              onChange={e => setIncludeBashrcDotfiles(e.target.checked)}
              className="mt-0.5 accent-emerald-500"
            />
            <div>
              <div className="font-medium text-gray-200">~/.bashrc & ~/.bash_aliases</div>
              <div className="text-gray-500 text-[11px]">Цветной PS1, история, 40+ полезных алиасов</div>
            </div>
          </label>

          <label className="flex items-start gap-2.5 p-2.5 bg-gray-900/60 rounded-lg border border-gray-800 hover:border-gray-700 cursor-pointer">
            <input
              type="checkbox"
              checked={installFzf}
              onChange={e => setInstallFzf(e.target.checked)}
              className="mt-0.5 accent-emerald-500"
            />
            <div>
              <div className="font-medium text-gray-200">fzf (fuzzy finder)</div>
              <div className="text-gray-500 text-[11px]">Умный интерактивный поиск файлов и команд</div>
            </div>
          </label>

          <label className="flex items-start gap-2.5 p-2.5 bg-gray-900/60 rounded-lg border border-gray-800 hover:border-gray-700 cursor-pointer">
            <input
              type="checkbox"
              checked={installDocker}
              onChange={e => setInstallDocker(e.target.checked)}
              className="mt-0.5 accent-emerald-500"
            />
            <div>
              <div className="font-medium text-gray-200">Docker CE + Compose Plugin</div>
              <div className="text-gray-500 text-[11px]">Официальный репозиторий Docker и права для пользователя</div>
            </div>
          </label>

          <label className="flex items-start gap-2.5 p-2.5 bg-gray-900/60 rounded-lg border border-gray-800 hover:border-gray-700 cursor-pointer">
            <input
              type="checkbox"
              checked={installNodeNvm}
              onChange={e => setInstallNodeNvm(e.target.checked)}
              className="mt-0.5 accent-emerald-500"
            />
            <div>
              <div className="font-medium text-gray-200">Node.js LTS (NVM)</div>
              <div className="text-gray-500 text-[11px]">Менеджер версий nvm и последняя LTS нода</div>
            </div>
          </label>

          <label className="flex items-start gap-2.5 p-2.5 bg-gray-900/60 rounded-lg border border-gray-800 hover:border-gray-700 cursor-pointer">
            <input
              type="checkbox"
              checked={installPython}
              onChange={e => setInstallPython(e.target.checked)}
              className="mt-0.5 accent-emerald-500"
            />
            <div>
              <div className="font-medium text-gray-200">Python 3 + pip + dev</div>
              <div className="text-gray-500 text-[11px]">python3-pip, python3-dev и обновление pip</div>
            </div>
          </label>

          <label className="flex items-start gap-2.5 p-2.5 bg-gray-900/60 rounded-lg border border-gray-800 hover:border-gray-700 cursor-pointer">
            <input
              type="checkbox"
              checked={createDirs}
              onChange={e => setCreateDirs(e.target.checked)}
              className="mt-0.5 accent-emerald-500"
            />
            <div>
              <div className="font-medium text-gray-200">Каталоги пользователя</div>
              <div className="text-gray-500 text-[11px]">~/Projects, ~/Documents, ~/Downloads, ~/Scripts</div>
            </div>
          </label>

          <label className="flex items-start gap-2.5 p-2.5 bg-gray-900/60 rounded-lg border border-gray-800 hover:border-gray-700 cursor-pointer">
            <input
              type="checkbox"
              checked={applyUserDotfiles}
              onChange={e => setApplyUserDotfiles(e.target.checked)}
              className="mt-0.5 accent-emerald-500"
            />
            <div>
              <div className="font-medium text-gray-200">apply-user-dotfiles.sh</div>
              <div className="text-gray-500 text-[11px]">Копирование в /home/* с бэкапами и chown</div>
            </div>
          </label>

          <label className="flex items-start gap-2.5 p-2.5 bg-gray-900/60 rounded-lg border border-gray-800 hover:border-gray-700 cursor-pointer">
            <input
              type="checkbox"
              checked={hardwareSensors}
              onChange={e => setHardwareSensors(e.target.checked)}
              className="mt-0.5 accent-emerald-500"
            />
            <div>
              <div className="font-medium text-gray-200">Bare-Metal утилиты</div>
              <div className="text-gray-500 text-[11px]">lm-sensors (температура CPU), strace</div>
            </div>
          </label>
        </div>

        {/* Git Configuration Inputs */}
        <div className="pt-3 border-t border-gray-800 grid grid-cols-1 md:grid-cols-2 gap-3 text-xs">
          <div>
            <label className="block text-gray-400 mb-1">Git User Name</label>
            <input
              type="text"
              value={gitName}
              onChange={e => setGitName(e.target.value)}
              className="w-full bg-gray-900 border border-gray-700 rounded px-2.5 py-1.5 text-gray-200 font-mono text-xs"
            />
          </div>
          <div>
            <label className="block text-gray-400 mb-1">Git User Email</label>
            <input
              type="email"
              value={gitEmail}
              onChange={e => setGitEmail(e.target.value)}
              className="w-full bg-gray-900 border border-gray-700 rounded px-2.5 py-1.5 text-gray-200 font-mono text-xs"
            />
          </div>
        </div>
      </div>

      {/* Script Preview & Action Toolbar */}
      <div className="rounded-xl overflow-hidden border border-[#30363d] bg-[#0d1117] shadow-lg">
        <div className="bg-[#161b22] px-4 py-3 border-b border-[#30363d] flex flex-wrap items-center justify-between gap-2">
          <div className="flex items-center space-x-2">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 inline-block"></span>
            <span className="text-xs font-semibold text-gray-200 font-mono">
              {preset === 'debian_setup' ? 'debian_setup.sh' : `${preset}.sh`}
            </span>
            <span className="text-[11px] text-gray-500">({scriptContent.split('\n').length} строк)</span>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={copyToClipboard}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-800 hover:bg-gray-700 text-gray-300 rounded-lg text-xs font-medium border border-gray-700 transition-colors"
            >
              {copied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
              <span>{copied ? 'Скопировано!' : 'Копировать скрипт'}</span>
            </button>

            <button
              onClick={downloadScript}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg text-xs font-medium transition-colors shadow-sm"
            >
              <Download className="w-3.5 h-3.5" />
              <span>Скачать .sh</span>
            </button>
          </div>
        </div>

        {/* Script Code View with Line Numbers */}
        <div className="p-4 overflow-x-auto max-h-[500px] text-xs font-mono text-gray-300 bg-[#0d1117]">
          <pre className="leading-relaxed">
            {scriptContent.split('\n').map((line, idx) => (
              <div key={idx} className="flex hover:bg-gray-800/40 px-1 rounded">
                <span className="w-10 text-gray-600 select-none text-right pr-4 font-mono text-[11px]">
                  {idx + 1}
                </span>
                <span
                  className={
                    line.startsWith('#')
                      ? 'text-gray-500'
                      : line.includes('log_info')
                      ? 'text-emerald-400'
                      : line.includes('sudo apt')
                      ? 'text-blue-300 font-semibold'
                      : 'text-gray-300'
                  }
                >
                  {line || ' '}
                </span>
              </div>
            ))}
          </pre>
        </div>
      </div>
    </div>
  );
};
