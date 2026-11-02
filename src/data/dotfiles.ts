export interface RepoFile {
  id: string;
  name: string;
  path: string;
  category: 'script' | 'bash' | 'tmux' | 'service';
  description: string;
  content: string;
}

export const LOGO_1 = `$$$$$$$$$$$$$$$$""$o$o$o$o$o$oo$$""$$$$$$$$$$$$$$$
$$$$$$$$$$$$""o$$$$$$$$$$"$"$$$$$$$o$"$$$$$$$$$$$$
$$$$$$$$$"$o$$$$""$oo $ ""      """$$$oo"$$$$$$$$$
$$$$$$$"o$$$$"   ""o  $oo o o       ""$$$o"$$$$$$$
$$$$$"o$$$"       oo$$$$$$$$$$o        "$$$o"$$$$$
$$$$"o$$$  $  o$$$$$$$$$$$$$$"$$oo       "$$$ $$$$
$$$"$$$"   "$$$$$$$$$$$$$$$$o$o$$$"        $$$o$$$
$$ $$$    o$$$$$$$$$$$$$$$$$$$$$$$$o o   o  "$$o"$
$"$$$"    o$$$$$$$$$"$$$$$$"" "$$$$$$"$$$$$  $$$"$
$o$$"    o$$$$$$$$$$o""$$$""""ooo"$$$$$$$$"   $$$"
$o$$"    o$$$$$$$$$$            ""oo"$"$o""   $$$o
o$$$     o$$$$$$$$$$                """""$    o$$o
o$$$    o$$$$$$$$$$$$o                   "o "oo$$o
o$$$  oo$$$$$$$$$$$$$$$$ooooooo$$$$$oo    $"$ "$$o
o$$$"  ""  $$$$$$$$$$$$$$$$$$$$$$$$$$$$o    " $$$
$ $$$       "$$$$$$$$$$$$$$$$$$$$$$$$$$$o    o$$"$
$$"$$o       "$$$$$$$$$$$$$$$$$$$$$$$$$$$o   $$$o$
$$o$$$o       $$""$$$$$$$$$$$$$$$$$$$$$$$o  $$$ $$
$$$o"$$o    "$""  "$""$$$$$$$$$$$$$$$$$$$oo$$$"$$$
$$$$o"$$$o        "     $$$$$$$$$$$$$$$$$o$$"o$$$$
$$$$$$o"$$$o         oo$$$$$$$$$$$$$$$$$$$$"o$$$$$
$$$$$$$$o"$$$$ooooo$$$$$$$$$$$$$$$$$$$$$$"o$$$$$$$
$$$$$$$$$$o""$$$$$$$$$$$$$$$$$$$$$$$$$"oo$$$$$$$$$
$$$$$$$$$$$$$o$""$$$$$$$$$$$$$$$$$""oo$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$o$o$"$"$"$"$oo$o$$$$$$$$$$$$$$$$`;

export const LOGO_2 = `  *********    *****    **
 *************************.*
****** *********** ** *******o
******* ********* **** ****\`-
******* ********* *****
 ****** ********** ****
## *****  ***** ##  ****
### *****      ###   ****
#,,, ***,,,    ##,,,  **,,,`;

export const LOGO_3 = `        #####
       #######
       ##O#O##
       #######
     ###########
    #############
   ###############
   ################
    ##############
      ##########
     #############
    ###############`;

export const INITIAL_SERVICES: { name: string; category: string; description: string; defaultActive: boolean }[] = [
  // Web & Proxies
  { name: 'nginx', category: 'Web & Proxies', description: 'Web server & reverse proxy', defaultActive: true },
  { name: 'apache2', category: 'Web & Proxies', description: 'Apache HTTP Server (Debian/Ubuntu)', defaultActive: false },
  { name: 'haproxy', category: 'Web & Proxies', description: 'High-availability TCP/HTTP load balancer', defaultActive: false },
  { name: 'traefik', category: 'Web & Proxies', description: 'Edge router and cloud-native proxy', defaultActive: false },
  { name: 'varnish', category: 'Web & Proxies', description: 'HTTP reverse proxy cache accelerator', defaultActive: false },

  // Databases & Cache
  { name: 'postgresql', category: 'Databases', description: 'Advanced object-relational database', defaultActive: true },
  { name: 'redis', category: 'Databases', description: 'In-memory key-value data store & cache', defaultActive: true },
  { name: 'mysql', category: 'Databases', description: 'MySQL relational database server', defaultActive: false },
  { name: 'mariadb', category: 'Databases', description: 'Open-source MariaDB fork of MySQL', defaultActive: false },
  { name: 'mongodb', category: 'Databases', description: 'NoSQL document database', defaultActive: false },
  { name: 'clickhouse-server', category: 'Databases', description: 'Column-oriented analytical DBMS', defaultActive: false },

  // Security & Remote
  { name: 'sshd', category: 'Security & System', description: 'OpenSSH remote server daemon', defaultActive: true },
  { name: 'fail2ban', category: 'Security & System', description: 'Brute-force intrusion prevention', defaultActive: true },
  { name: 'ufw', category: 'Security & System', description: 'Uncomplicated Firewall', defaultActive: false },
  { name: 'firewalld', category: 'Security & System', description: 'Dynamic firewall daemon', defaultActive: false },

  // Containers & K8s
  { name: 'docker', category: 'Containers', description: 'Docker container management engine', defaultActive: true },
  { name: 'containerd', category: 'Containers', description: 'Core container runtime', defaultActive: true },
  { name: 'k3s', category: 'Containers', description: 'Lightweight certified Kubernetes distro', defaultActive: false },

  // Proxmox Virtualization
  { name: 'pve-cluster', category: 'Proxmox VE', description: 'Cluster filesystem pmxcfs daemon', defaultActive: false },
  { name: 'pvedaemon', category: 'Proxmox VE', description: 'Proxmox VE core management API', defaultActive: false },
  { name: 'pveproxy', category: 'Proxmox VE', description: 'Proxmox VE web GUI REST API proxy', defaultActive: false },
  { name: 'pvestatd', category: 'Proxmox VE', description: 'VM & metrics polling stats daemon', defaultActive: false },

  // Monitoring
  { name: 'zabbix-agent2', category: 'Monitoring', description: 'Zabbix Agent 2 monitoring collector', defaultActive: true },
  { name: 'prometheus', category: 'Monitoring', description: 'Time-series monitoring & alerting toolkit', defaultActive: false },
  { name: 'node_exporter', category: 'Monitoring', description: 'Hardware and OS metrics exporter', defaultActive: false },
  { name: 'grafana-server', category: 'Monitoring', description: 'Interactive dashboard visualization platform', defaultActive: false },

  // Mail & Groupware
  { name: 'postfix', category: 'Mail', description: 'High-performance Mail Transfer Agent (MTA)', defaultActive: false },
  { name: 'dovecot', category: 'Mail', description: 'Secure IMAP and POP3 mail server', defaultActive: false },
  { name: 'spamassassin', category: 'Mail', description: 'Email spam detection filter', defaultActive: false },

  // 1C:Enterprise
  { name: 'srv1cv83', category: '1C:Enterprise', description: '1C:Enterprise 8.3 cluster server agent', defaultActive: false },
  { name: 'ras', category: '1C:Enterprise', description: '1C Remote Administration Server', defaultActive: false }
];

export interface AliasItem {
  name: string;
  command: string;
  category: 'Navigation' | 'Files' | 'System' | 'Updates' | 'Git' | 'Network' | 'Functions' | 'Configs';
  description: string;
  usageExample?: string;
  type: 'alias' | 'function';
}

export const REPO_ALIASES: AliasItem[] = [
  // Navigation
  { name: '..', command: 'cd ..', category: 'Navigation', description: 'Перейти на один уровень вверх', type: 'alias' },
  { name: '...', command: 'cd ../..', category: 'Navigation', description: 'Перейти на два уровня вверх', type: 'alias' },
  { name: '....', command: 'cd ../../..', category: 'Navigation', description: 'Перейти на три уровня вверх', type: 'alias' },
  { name: '~', command: 'cd ~', category: 'Navigation', description: 'Перейти в домашнюю директорию', type: 'alias' },
  { name: '-', command: 'cd -', category: 'Navigation', description: 'Вернуться в предыдущую рабочую директорию', type: 'alias' },
  { name: 'lsa', command: 'ls -alh', category: 'Navigation', description: 'Полный подробный листинг файлов со скрытыми', type: 'alias' },

  // Files
  { name: 'cp', command: 'cp -iv', category: 'Files', description: 'Копировать с подтверждением перезаписи и выводом', type: 'alias' },
  { name: 'mv', command: 'mv -iv', category: 'Files', description: 'Переместить с подтверждением и подробным выводом', type: 'alias' },
  { name: 'rm', command: 'rm -Iv', category: 'Files', description: 'Безопасное удаление: подтверждение при 3+ файлах', type: 'alias' },
  { name: 'mkdir', command: 'mkdir -pv', category: 'Files', description: 'Создать дерево папок с выводом созданных директорий', type: 'alias' },
  { name: 'df', command: 'df -h', category: 'Files', description: 'Свободное место на смонтированных дисках (GB/MB)', type: 'alias' },
  { name: 'du', command: 'du -h', category: 'Files', description: 'Размер файлов и папок в удобных единицах', type: 'alias' },
  { name: 'duh', command: 'du -sh *', category: 'Files', description: 'Размер содержимого каждого элемента текущей папки', type: 'alias' },
  { name: 'cx', command: 'chmod +x', category: 'Files', description: 'Сделать файл исполняемым', usageExample: 'cx script.sh', type: 'alias' },

  // System
  { name: 'ps', command: 'ps aux', category: 'System', description: 'Список всех процессов в системе', type: 'alias' },
  { name: 'psg', command: 'ps aux | grep', category: 'System', description: 'Поиск процессов по имени', usageExample: 'psg nginx', type: 'alias' },
  { name: 'top', command: 'top -d 1', category: 'System', description: 'Интерактивный top с обновлением каждую секунду', type: 'alias' },
  { name: 'free', command: 'free -h', category: 'System', description: 'Использование RAM и Swap в человекочитаемом формате', type: 'alias' },
  { name: 'ports', command: 'ss -tulnp', category: 'System', description: 'Все слушающие TCP/UDP сокеты с именами процессов', type: 'alias' },
  { name: 'myip', command: 'curl -s ifconfig.me', category: 'System', description: 'Узнать внешний публичный IP адрес сервера', type: 'alias' },
  { name: 'disk', command: 'du -aBM 2>/dev/null | sort -nr | head -n 30', category: 'System', description: 'Топ 30 самых тяжёлых файлов на диске', type: 'alias' },

  // Updates
  { name: 'update', command: 'sudo apt update && sudo apt upgrade -y', category: 'Updates', description: 'Полное обновление списка репозиториев и пакетов', type: 'alias' },
  { name: 'install', command: 'sudo apt install', category: 'Updates', description: 'Быстрая установка пакетов', usageExample: 'install htop vim', type: 'alias' },
  { name: 'remove', command: 'sudo apt remove', category: 'Updates', description: 'Удаление пакета', type: 'alias' },
  { name: 'clean', command: 'sudo apt clean && sudo apt autoremove -y', category: 'Updates', description: 'Очистка кэша apt и неиспользуемых зависимостей', type: 'alias' },

  // Configs
  { name: 'ebrc', command: '${EDITOR:-nano} ~/.bashrc && source ~/.bashrc', category: 'Configs', description: 'Редактировать .bashrc и сразу применить без перезахода', type: 'alias' },
  { name: 'ebal', command: '${EDITOR:-nano} ~/.bash_aliases && source ~/.bash_aliases', category: 'Configs', description: 'Редактировать алиасы и немедленно активировать их', type: 'alias' },
  { name: 'sbrc', command: 'source ~/.bashrc', category: 'Configs', description: 'Перезагрузить .bashrc в текущей сессии', type: 'alias' },
  { name: 'hosts', command: 'sudo ${EDITOR:-nano} /etc/hosts', category: 'Configs', description: 'Быстрое редактирование /etc/hosts', type: 'alias' },

  // Git
  { name: 'g', command: 'git', category: 'Git', description: 'Сокращение команды git', type: 'alias' },
  { name: 'gs', command: 'git status', category: 'Git', description: 'Статус рабочего каталога Git', type: 'alias' },
  { name: 'ga', command: 'git add .', category: 'Git', description: 'Добавить все изменения в staging', type: 'alias' },
  { name: 'gc', command: 'git commit -m', category: 'Git', description: 'Создать коммит с сообщением', usageExample: 'gc "feat: add motd"', type: 'alias' },
  { name: 'gp', command: 'git push', category: 'Git', description: 'Отправить ветку на удалённый репозиторий', type: 'alias' },
  { name: 'gl', command: 'git log --oneline --graph --decorate -15', category: 'Git', description: 'Красивое дерево последних 15 коммитов', type: 'alias' },
  { name: 'gd', command: 'git diff', category: 'Git', description: 'Разница между рабочими файлами и индексом', type: 'alias' },
  { name: 'gb', command: 'git branch', category: 'Git', description: 'Список локальных веток', type: 'alias' },

  // Network
  { name: 'ping', command: 'ping -c 5', category: 'Network', description: 'Пинг ровно 5 пакетов вместо бесконечного цикла', type: 'alias' },
  { name: 'wget', command: 'wget -c', category: 'Network', description: 'Скачивание с автоматической докачкой при обрыве', type: 'alias' },

  // Utility Functions
  {
    name: 'extract',
    command: `extract() {
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.tar.xz)  tar xJf "$1" ;;
    *.zip)     unzip "$1"   ;;
    *.7z)      7z x "$1"    ;;
    *.gz)      gunzip "$1"  ;;
    *.bz2)     bunzip2 "$1" ;;
    *.rar)     unrar x "$1" ;;
    *) echo "Unknown format: $1" ;;
  esac
}`,
    category: 'Functions',
    description: 'Универсальная распаковка архивов любого формата (tar, zip, 7z, rar, bz2, xz)',
    usageExample: 'extract archive.tar.gz',
    type: 'function'
  },
  {
    name: 'genpass',
    command: `genpass() {
  tr -dc 'A-Za-z0-9!@#$%' </dev/urandom | head -c "\${1:-16}"; echo;
}`,
    category: 'Functions',
    description: 'Генерация криптографически стойкого случайного пароля заданной длины (по умолч. 16)',
    usageExample: 'genpass 24',
    type: 'function'
  },
  {
    name: 'bak',
    command: `bak() { cp "$1" "$1.$(date +%F).bak"; }`,
    category: 'Functions',
    description: 'Создание резервной копии файла с текущей датой в имени',
    usageExample: 'bak nginx.conf',
    type: 'function'
  },
  {
    name: 'mkcd',
    command: `mkcd() { mkdir -p "$1" && cd "$1"; }`,
    category: 'Functions',
    description: 'Создать директорию (включая вложенные) и сразу перейти в неё',
    usageExample: 'mkcd /opt/myapp/configs',
    type: 'function'
  },
  {
    name: 'ff',
    command: `ff() { find . -name "*$1*" 2>/dev/null; }`,
    category: 'Functions',
    description: 'Быстрый поиск файла по фрагменту имени в текущей папке',
    usageExample: 'ff default.conf',
    type: 'function'
  },
  {
    name: 'ft',
    command: `ft() { grep -rl "$1" "\${2:-.}" 2>/dev/null; }`,
    category: 'Functions',
    description: 'Поиск файлов, содержащих указанный текст',
    usageExample: 'ft "error_log" /etc/nginx',
    type: 'function'
  },
  {
    name: 'ips',
    command: `ips() { ip -br addr show | awk '{print $1, $3}'; }`,
    category: 'Functions',
    description: 'Компактный список всех сетевых интерфейсов и их IP адресов',
    usageExample: 'ips',
    type: 'function'
  },
  {
    name: 'chkport',
    command: `chkport() { timeout 2 bash -c "cat < /dev/null > /dev/tcp/$1/$2" && echo "Открыт" || echo "Закрыт"; }`,
    category: 'Functions',
    description: 'Проверка доступности сетевого порта через TCP сокет без nmap',
    usageExample: 'chkport 10.0.0.1 22',
    type: 'function'
  },
  {
    name: 'memtop',
    command: `memtop() { ps aux --sort=-%mem | head -n 11; }`,
    category: 'Functions',
    description: 'Топ-10 процессов системы по потреблению оперативной памяти',
    usageExample: 'memtop',
    type: 'function'
  },
  {
    name: 'cputop',
    command: `cputop() { ps aux --sort=-%cpu | head -n 11; }`,
    category: 'Functions',
    description: 'Топ-10 процессов системы по потреблению CPU',
    usageExample: 'cputop',
    type: 'function'
  },
  {
    name: 'tailf',
    command: `tailf() { tail -n "\${2:-20}" -f "$1"; }`,
    category: 'Functions',
    description: 'Просмотр последних N строк лога в реальном времени',
    usageExample: 'tailf /var/log/syslog 50',
    type: 'function'
  },
  {
    name: 'every',
    command: `every() { local n=$1; shift; while true; do clear; "$@"; sleep "$n"; done; }`,
    category: 'Functions',
    description: 'Периодическое повторение команды каждые N секунд с очисткой экрана (как watch)',
    usageExample: 'every 2 df -h',
    type: 'function'
  }
];

export const TMUX_HOTKEYS = [
  { prefix: 'Ctrl+a', key: '=', desc: 'Разделить окно вертикально (панели рядом)', action: 'split-window -h' },
  { prefix: 'Ctrl+a', key: '-', desc: 'Разделить окно горизонтально (панели сверху/снизу)', action: 'split-window -v' },
  { prefix: 'Ctrl+a', key: 'x / Alt+e', desc: 'Закрыть текущую панель без подтверждения', action: 'kill-pane' },
  { prefix: 'Ctrl+a', key: 'z', desc: 'Развернуть / восстановить панель на весь экран', action: 'resize-pane -Z' },
  { prefix: 'Ctrl+a', key: 'S', desc: 'Синхронизация ввода во все панели одновременно (⚡SYNC)', action: 'setw synchronize-panes' },
  { prefix: 'Ctrl+a', key: 'c', desc: 'Новое окно в текущей рабочей папке', action: 'new-window -c #{pane_current_path}' },
  { prefix: 'Ctrl+a', key: ',', desc: 'Переименовать текущее окно', action: 'command-prompt -I #W "rename-window -- \'%%\'"' },
  { prefix: 'None', key: 'Alt+1..9', desc: 'Быстро перейти на окно или создать новое с этим номером', action: 'select-window or new-window' },
  { prefix: 'None', key: 'Alt+q', desc: 'Закрыть текущее окно (с защитой и подтверждением)', action: 'confirm-before kill-window' },
  { prefix: 'Ctrl+a', key: 'd', desc: 'Отключиться от tmux (сессия продолжает работать в фоне)', action: 'detach-client' },
  { prefix: 'Ctrl+a', key: 's', desc: 'Интерактивный список активных сессий', action: 'choose-tree -s' },
  { prefix: 'Ctrl+a', key: 'r', desc: 'Перезагрузить ~/.tmux.conf без выхода из сессии', action: 'source-file ~/.tmux.conf' },
  { prefix: 'Ctrl+a', key: '[', desc: 'Режим скролла/копирования vi (v выбор, y копировать)', action: 'copy-mode-vi' },
  { prefix: 'Ctrl+a', key: ']', desc: 'Вставить скопированный текст из буфера tmux', action: 'paste-buffer' },
  { prefix: 'Ctrl+a', key: 'h', desc: 'Открыть встроенную всплывающую памятку по горячим клавишам', action: 'display-popup cheatsheet' },
  { prefix: 'Mouse', key: 'Click & Drag', desc: 'Выбор панели, окна, изменение размера границ и скролл истории', action: 'mouse on' }
];
