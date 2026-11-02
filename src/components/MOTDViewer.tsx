import React, { useState } from 'react';
import { Terminal, RefreshCw, Sliders, ShieldCheck, Cpu, HardDrive, Network, Mail, Info, Play, Check, Copy } from 'lucide-react';
import { LOGO_1, LOGO_2, LOGO_3, INITIAL_SERVICES } from '../data/dotfiles';

interface MOTDViewerProps {
  serverInfoText: string;
  services: { name: string; category: string; description: string; defaultActive: boolean }[];
}

export const MOTDViewer: React.FC<MOTDViewerProps> = ({ serverInfoText, services }) => {
  // Server state parameters
  const [hostname, setHostname] = useState('deb-srv-core01');
  const [osName, setOsName] = useState('Debian GNU/Linux 12 (bookworm)');
  const [kernel, setKernel] = useState('6.1.0-28-amd64');
  const [uptimeStr, setUptimeStr] = useState('42 days, 7 hours, 18 mins');
  const [ipAddress, setIpAddress] = useState('10.5.12.84/24');
  const [ifaceName, setIfaceName] = useState('ens18');
  const [secondaryIp, setSecondaryIp] = useState('172.16.40.10/24');
  const [secondaryIface, setSecondaryIface] = useState('wg0');
  
  const [cpuModel, setCpuModel] = useState('AMD EPYC 7763 64-Core Processor');
  const [cpuCores, setCpuCores] = useState(8);
  const [cpuThreads, setCpuThreads] = useState(16);
  const [load1m, setLoad1m] = useState('0.42');
  const [load5m, setLoad5m] = useState('0.58');
  const [load15m, setLoad15m] = useState('0.61');

  const [ramPct, setRamPct] = useState(48);
  const [ramUsed, setRamUsed] = useState('7.6G');
  const [ramTotal, setRamTotal] = useState('16.0G');
  const [swapPct, setSwapPct] = useState(12);
  const [swapUsed, setSwapUsed] = useState('980M');
  const [swapTotal, setSwapTotal] = useState('8.0G');

  const [activeSessions, setActiveSessions] = useState(2);
  const [failedLogins, setFailedLogins] = useState(0);

  const [logoChoice, setLogoChoice] = useState<'auto' | 'logo1' | 'logo2' | 'logo3'>('auto');
  const [showConfigDrawer, setShowConfigDrawer] = useState(false);
  const [copied, setCopied] = useState(false);

  // Terminal command prompt simulation
  const [commandInput, setCommandInput] = useState('');
  const [terminalHistory, setTerminalHistory] = useState<string[]>([]);

  // Calculate active logo
  const resolvedLogo = () => {
    if (logoChoice === 'logo1') return LOGO_1;
    if (logoChoice === 'logo2') return LOGO_2;
    if (logoChoice === 'logo3') return LOGO_3;
    // Auto IP detection logic from .bash_welcome
    if (ipAddress.startsWith('10.5') || ipAddress.startsWith('172.16')) {
      return LOGO_2;
    }
    return LOGO_1;
  };

  // Generate ASCII Progress bar
  const renderProgressBar = (pct: number) => {
    const width = 20;
    const filled = Math.min(width, Math.max(0, Math.round((pct * width) / 100)));
    const empty = width - filled;
    const colorClass = pct >= 90 ? 'text-red-400' : pct >= 70 ? 'text-amber-400' : 'text-emerald-400';
    return (
      <span className="font-mono">
        <span className={colorClass}>{'█'.repeat(filled)}</span>
        <span className="text-gray-600">{'░'.repeat(empty)}</span>
        <span className={`ml-2 font-bold ${colorClass}`}>{pct.toString().padStart(3, ' ')}%</span>
      </span>
    );
  };

  const handleCommandSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const cmd = commandInput.trim();
    if (!cmd) return;

    let response = '';
    switch (cmd.toLowerCase()) {
      case 'help':
        response = 'Доступные команды: welcome_screen, genpass, free, df, ports, ips, clear, exit';
        break;
      case 'clear':
        setTerminalHistory([]);
        setCommandInput('');
        return;
      case 'welcome_screen':
        response = '[Перерисовка экрана приветствия...]';
        break;
      case 'genpass':
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%';
        let pass = '';
        for (let i = 0; i < 16; i++) pass += chars.charAt(Math.floor(Math.random() * chars.length));
        response = `Сгенерированный пароль: ${pass}`;
        break;
      case 'free':
      case 'free -h':
        response = `              total        used        free      shared  buff/cache   available\nMem:           ${ramTotal}        ${ramUsed}        8.4G        120M        4.2G        8.1G\nSwap:          ${swapTotal}        ${swapUsed}        7.0G`;
        break;
      case 'df':
      case 'df -h':
        response = 'Filesystem      Size  Used Avail Use% Mounted on\n/dev/sda1        50G   18G   30G  38% /\n/dev/sdb1       200G   82G  108G  44% /var/lib/docker\ntmpfs           7.8G     0  7.8G   0% /dev/shm';
        break;
      case 'ips':
        response = `${ifaceName}    ${ipAddress}\n${secondaryIface}     ${secondaryIp}`;
        break;
      case 'ports':
        response = 'Netid State  Recv-Q Send-Q Local Address:Port Peer Address:Port Process\ntcp   LISTEN 0      128          0.0.0.0:22         0.0.0.0:*    users:(("sshd",pid=842,fd=3))\ntcp   LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=1120,fd=6))\ntcp   LISTEN 0      511          0.0.0.0:443        0.0.0.0:*    users:(("nginx",pid=1120,fd=7))\ntcp   LISTEN 0      128        127.0.0.1:5432       0.0.0.0:*    users:(("postgres",pid=912,fd=7))';
        break;
      default:
        response = `bash: ${cmd}: команда не найдена. Наберите 'help' для справки.`;
    }

    setTerminalHistory(prev => [...prev, `$ ${cmd}`, response]);
    setCommandInput('');
  };

  const copyMotdText = () => {
    const text = document.getElementById('motd-ansi-canvas')?.innerText || '';
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  // Group services for the 2-column bash welcome display
  const activeServicesList = services.filter(s => s.defaultActive);
  const half = Math.ceil(activeServicesList.length / 2);
  const leftCol = activeServicesList.slice(0, half);
  const rightCol = activeServicesList.slice(half);

  return (
    <div className="space-y-4">
      {/* Top action bar */}
      <div className="flex flex-wrap items-center justify-between gap-3 bg-[#131923] p-3.5 rounded-xl border border-gray-800 shadow-sm">
        <div className="flex items-center space-x-3">
          <div className="p-2 bg-emerald-500/10 text-emerald-400 rounded-lg border border-emerald-500/20">
            <Terminal className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-base font-semibold text-white flex items-center gap-2">
              MOTD Welcome Screen Simulator
              <span className="text-xs px-2 py-0.5 bg-blue-500/20 text-blue-300 rounded border border-blue-500/30 font-mono">
                /etc/bash/.bash_welcome
              </span>
            </h2>
            <p className="text-xs text-gray-400">
              Высокоточная интерактивная эмуляция экрана приветствия bash с живыми метриками и статусами служб
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowConfigDrawer(!showConfigDrawer)}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors border ${
              showConfigDrawer
                ? 'bg-emerald-600/20 text-emerald-300 border-emerald-500/40'
                : 'bg-gray-800 hover:bg-gray-700 text-gray-300 border-gray-700'
            }`}
          >
            <Sliders className="w-3.5 h-3.5" />
            <span>Параметры сервера</span>
          </button>

          <button
            onClick={copyMotdText}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-800 hover:bg-gray-700 text-gray-300 rounded-lg text-xs font-medium border border-gray-700 transition-colors"
          >
            {copied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
            <span>{copied ? 'Скопировано!' : 'Копировать вывод'}</span>
          </button>
        </div>
      </div>

      {/* Optional Parameters Control Panel */}
      {showConfigDrawer && (
        <div className="bg-[#10151f] p-4 rounded-xl border border-gray-800 grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-4 text-xs animate-in fade-in duration-150">
          <div>
            <label className="block text-gray-400 mb-1">Имя хоста (FQDN)</label>
            <input
              type="text"
              value={hostname}
              onChange={e => setHostname(e.target.value)}
              className="w-full bg-gray-900 border border-gray-700 rounded px-2.5 py-1.5 text-gray-200 focus:border-emerald-500 outline-none font-mono"
            />
          </div>
          <div>
            <label className="block text-gray-400 mb-1">Дистрибутив ОС</label>
            <select
              value={osName}
              onChange={e => setOsName(e.target.value)}
              className="w-full bg-gray-900 border border-gray-700 rounded px-2.5 py-1.5 text-gray-200 focus:border-emerald-500 outline-none"
            >
              <option value="Debian GNU/Linux 12 (bookworm)">Debian 12 Bookworm</option>
              <option value="ALT Server 10.2 (Hyun)">ALT Linux Server 10.2</option>
              <option value="Ubuntu 24.04.1 LTS">Ubuntu 24.04 LTS</option>
              <option value="Proxmox Virtual Environment 8.2">Proxmox VE 8.2</option>
            </select>
          </div>
          <div>
            <label className="block text-gray-400 mb-1">Основной IP & Интерфейс</label>
            <div className="flex gap-2">
              <input
                type="text"
                value={ifaceName}
                onChange={e => setIfaceName(e.target.value)}
                className="w-20 bg-gray-900 border border-gray-700 rounded px-2 py-1.5 text-gray-200 font-mono"
              />
              <input
                type="text"
                value={ipAddress}
                onChange={e => setIpAddress(e.target.value)}
                className="flex-1 bg-gray-900 border border-gray-700 rounded px-2 py-1.5 text-gray-200 font-mono"
              />
            </div>
          </div>
          <div>
            <label className="block text-gray-400 mb-1">ASCII Логотип</label>
            <select
              value={logoChoice}
              onChange={e => setLogoChoice(e.target.value as any)}
              className="w-full bg-gray-900 border border-gray-700 rounded px-2.5 py-1.5 text-gray-200 focus:border-emerald-500 outline-none"
            >
              <option value="auto">Авто (по IP подсети .bash_welcome)</option>
              <option value="logo1">Логотип #1 (Debian Swirl)</option>
              <option value="logo2">Логотип #2 (Компактный)</option>
              <option value="logo3">Логотип #3 (Пингвин Tux)</option>
            </select>
          </div>
          <div>
            <label className="block text-gray-400 mb-1">RAM нагрузка ({ramPct}%)</label>
            <input
              type="range"
              min="5"
              max="98"
              value={ramPct}
              onChange={e => {
                const val = parseInt(e.target.value);
                setRamPct(val);
                setRamUsed(`${((val * 16) / 100).toFixed(1)}G`);
              }}
              className="w-full accent-emerald-500 cursor-pointer"
            />
          </div>
          <div>
            <label className="block text-gray-400 mb-1">SWAP нагрузка ({swapPct}%)</label>
            <input
              type="range"
              min="0"
              max="95"
              value={swapPct}
              onChange={e => {
                const val = parseInt(e.target.value);
                setSwapPct(val);
                setSwapUsed(val === 0 ? '0M' : `${Math.round((val * 8192) / 100)}M`);
              }}
              className="w-full accent-emerald-500 cursor-pointer"
            />
          </div>
          <div>
            <label className="block text-gray-400 mb-1">Неудачных входов SSH</label>
            <input
              type="number"
              min="0"
              max="500"
              value={failedLogins}
              onChange={e => setFailedLogins(parseInt(e.target.value) || 0)}
              className="w-full bg-gray-900 border border-gray-700 rounded px-2.5 py-1.5 text-gray-200 font-mono"
            />
          </div>
          <div>
            <label className="block text-gray-400 mb-1">Активных сессий</label>
            <input
              type="number"
              min="1"
              max="20"
              value={activeSessions}
              onChange={e => setActiveSessions(parseInt(e.target.value) || 1)}
              className="w-full bg-gray-900 border border-gray-700 rounded px-2.5 py-1.5 text-gray-200 font-mono"
            />
          </div>
        </div>
      )}

      {/* Terminal Window Container */}
      <div className="rounded-xl overflow-hidden border border-[#30363d] bg-[#0d1117] shadow-2xl font-mono text-sm">
        {/* Terminal Header */}
        <div className="bg-[#161b22] px-4 py-2.5 border-b border-[#30363d] flex items-center justify-between select-none">
          <div className="flex items-center space-x-2">
            <span className="w-3 h-3 rounded-full bg-[#f85149] inline-block"></span>
            <span className="w-3 h-3 rounded-full bg-[#e3b341] inline-block"></span>
            <span className="w-3 h-3 rounded-full bg-[#2ea043] inline-block"></span>
            <span className="ml-3 text-xs text-gray-400 font-medium tracking-wide">
              root@{hostname}: ~ (xterm-256color)
            </span>
          </div>
          <div className="text-xs text-gray-500 font-mono flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            <span>SSH: 22/tcp</span>
          </div>
        </div>

        {/* MOTD Screen Output Body */}
        <div id="motd-ansi-canvas" className="p-5 overflow-x-auto text-gray-300 leading-relaxed select-text">
          {/* Logo & Date */}
          <div className="grid grid-cols-1 md:grid-cols-12 gap-4 items-start pb-2">
            <div className="md:col-span-8 text-blue-400 whitespace-pre text-xs leading-none font-bold overflow-x-auto">
              {resolvedLogo()}
            </div>
            <div className="md:col-span-4 text-amber-300 text-xs font-semibold md:text-right pt-1">
              {new Date().toLocaleDateString('ru-RU', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric'
              })} | {new Date().toLocaleTimeString('ru-RU')} MSK
            </div>
          </div>

          <div className="text-gray-600 my-2">────────────────────────────────────────────────────</div>

          {/* 1. Host / OS / Kernel / Uptime */}
          <div className="space-y-1">
            <div className="flex">
              <span className="w-20 text-white font-bold">Хост</span>
              <span className="text-emerald-400 font-semibold">{hostname}</span>
            </div>
            <div className="flex flex-wrap items-center gap-2">
              <span className="w-20 text-white font-bold">ОС</span>
              <span className="text-emerald-400">{osName}</span>
              <span className="text-gray-500 text-xs">kernel: {kernel}</span>
            </div>
            <div className="flex">
              <span className="w-20 text-white font-bold">Аптайм</span>
              <span className="text-amber-300">{uptimeStr}</span>
            </div>
          </div>

          <div className="text-gray-600 my-2">────────────────────────────────────────────────────</div>

          {/* 2. Network */}
          <div>
            <div className="text-white font-bold mb-1">Сеть</div>
            <div className="space-y-0.5 pl-4">
              <div className="flex gap-4">
                <span className="text-blue-400 font-bold w-16">{ifaceName}</span>
                <span className="text-gray-300">{ipAddress}</span>
              </div>
              <div className="flex gap-4">
                <span className="text-blue-400 font-bold w-16">{secondaryIface}</span>
                <span className="text-gray-300">{secondaryIp}</span>
              </div>
            </div>
          </div>

          <div className="text-gray-600 my-2">────────────────────────────────────────────────────</div>

          {/* 3. CPU */}
          <div className="space-y-1">
            <div className="flex">
              <span className="w-20 text-white font-bold">CPU</span>
              <span className="text-gray-400">{cpuModel}</span>
            </div>
            <div className="flex flex-wrap items-center gap-4 pl-20 text-xs">
              <div>
                <span className="text-white font-semibold">Ядра: </span>
                <span className="text-emerald-400 font-bold">{cpuCores}C/{cpuThreads}T</span>
              </div>
              <div>
                <span className="text-white font-semibold">Load: </span>
                <span className="text-amber-300 font-bold">{load1m}</span>
                <span className="text-gray-500">/1м </span>
                <span className="text-amber-300 font-bold">{load5m}</span>
                <span className="text-gray-500">/5м </span>
                <span className="text-amber-300 font-bold">{load15m}</span>
                <span className="text-gray-500">/15м</span>
              </div>
            </div>
          </div>

          <div className="text-gray-600 my-2">────────────────────────────────────────────────────</div>

          {/* 4. RAM + SWAP */}
          <div className="space-y-1.5">
            <div className="flex items-center">
              <span className="w-16 text-white font-bold">RAM</span>
              {renderProgressBar(ramPct)}
              <span className="text-gray-400 ml-4 text-xs">{ramUsed}/{ramTotal}</span>
            </div>
            <div className="flex items-center">
              <span className="w-16 text-white font-bold">SWAP</span>
              {renderProgressBar(swapPct)}
              <span className="text-gray-400 ml-4 text-xs">{swapUsed}/{swapTotal}</span>
            </div>
          </div>

          <div className="text-gray-600 my-2">────────────────────────────────────────────────────</div>

          {/* 5. Disks */}
          <div>
            <div className="text-white font-bold mb-1">Диски</div>
            <div className="space-y-0.5 pl-4 text-xs">
              <div className="flex items-center gap-2">
                <span className="text-blue-400 font-bold w-24">/dev/sda1</span>
                <span className="text-gray-500">→</span>
                <span className="w-24 text-gray-200">/</span>
                <span className="text-emerald-400 font-semibold">18G</span>
                <span className="text-gray-500">/50G</span>
                <span className="text-emerald-400">(36%)</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-blue-400 font-bold w-24">/dev/sdb1</span>
                <span className="text-gray-500">→</span>
                <span className="w-24 text-gray-200">/var/lib/docker</span>
                <span className="text-emerald-400 font-semibold">82G</span>
                <span className="text-gray-500">/200G</span>
                <span className="text-emerald-400">(41%)</span>
              </div>
            </div>
          </div>

          <div className="text-gray-600 my-2">────────────────────────────────────────────────────</div>

          {/* 6. Sessions & Logins */}
          <div className="space-y-1">
            <div className="flex items-center gap-2">
              <span className="w-20 text-white font-bold">Сессии</span>
              <span className="text-gray-300">активных:</span>
              <span className="text-amber-300 font-bold">{activeSessions}</span>
              <span className="text-gray-600">|</span>
              <span className="text-gray-300">неудачных входов сегодня:</span>
              <span className={`font-bold ${failedLogins > 0 ? 'text-red-400' : 'text-emerald-400'}`}>
                {failedLogins}
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span className="w-20 text-white font-bold">Вход</span>
              <span className="text-gray-400 text-xs">предыдущий: pts/0 10.5.10.15 сб ноя 1 18:24</span>
            </div>
          </div>

          <div className="text-gray-600 my-2">────────────────────────────────────────────────────</div>

          {/* 7. Services (2 columns dynamic layout) */}
          <div>
            <div className="text-white font-bold mb-1.5">Сервисы</div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-1 pl-4 text-xs">
              {leftCol.map((svc, idx) => {
                const rightSvc = rightCol[idx];
                return (
                  <React.Fragment key={svc.name}>
                    <div className="flex items-center gap-2">
                      <span className="text-emerald-400 font-bold">●</span>
                      <span className="text-gray-200 w-32 font-medium">{svc.name}</span>
                      <span className="text-gray-500 text-[11px] truncate">{svc.description}</span>
                    </div>
                    {rightSvc ? (
                      <div className="flex items-center gap-2">
                        <span className="text-emerald-400 font-bold">●</span>
                        <span className="text-gray-200 w-32 font-medium">{rightSvc.name}</span>
                        <span className="text-gray-500 text-[11px] truncate">{rightSvc.description}</span>
                      </div>
                    ) : <div />}
                  </React.Fragment>
                );
              })}
            </div>
          </div>

          <div className="text-gray-600 my-2">────────────────────────────────────────────────────</div>

          {/* 8. Mail */}
          <div className="space-y-1">
            <div className="flex items-center gap-2">
              <span className="w-20 text-white font-bold">Почта</span>
              <span className="text-amber-300 font-bold">2</span>
              <span className="text-gray-400">писем в /var/mail/root</span>
            </div>
            <div className="pl-4 text-xs space-y-0.5">
              <div className="flex gap-2">
                <span className="text-gray-500"> 1.</span>
                <span className="text-white">Package updates avai...</span>
                <span className="text-gray-500">от:</span>
                <span className="text-gray-300">cron</span>
              </div>
              <div className="flex gap-2">
                <span className="text-gray-500"> 2.</span>
                <span className="text-white">Zabbix: Node disk space</span>
                <span className="text-gray-500">от:</span>
                <span className="text-gray-300">zabbix</span>
              </div>
              <div className="text-gray-600 text-[11px] pt-1">
                Читать: mail │ mutt │ cat /var/mail/root
              </div>
            </div>
          </div>

          <div className="text-gray-600 my-2">────────────────────────────────────────────────────</div>

          {/* 9. Server Description (.server_info) */}
          <div>
            <div className="text-white font-bold mb-1">Сервер</div>
            <div className="pl-4 text-xs text-gray-400 whitespace-pre-wrap leading-relaxed">
              {serverInfoText || 'Сервер настроен по стандартам Van-Hoffen/debian_init'}
            </div>
          </div>

          <div className="text-gray-600 my-2">────────────────────────────────────────────────────</div>

          {/* Command history output if any */}
          {terminalHistory.length > 0 && (
            <div className="mt-4 pt-2 border-t border-gray-800 space-y-1">
              {terminalHistory.map((line, idx) => (
                <div
                  key={idx}
                  className={`text-xs whitespace-pre-wrap ${
                    line.startsWith('$') ? 'text-emerald-400 font-bold' : 'text-gray-300'
                  }`}
                >
                  {line}
                </div>
              ))}
            </div>
          )}

          {/* Interactive Shell Prompt matching PS1 from .bashrc */}
          <form onSubmit={handleCommandSubmit} className="mt-4 flex items-center gap-1.5 text-xs">
            <span className="text-gray-500 font-bold">[</span>
            <span className="text-gray-400 underline font-semibold">22:19</span>
            <span className="text-gray-500 font-bold">]</span>
            <span className="text-purple-400 font-bold">[</span>
            <span className="text-orange-400 font-bold">{104 + terminalHistory.length}</span>
            <span className="text-purple-400 font-bold">]</span>
            <span className="text-red-400 font-bold">root</span>
            <span className="text-amber-400 font-bold">@</span>
            <span className="text-blue-400 font-bold">{hostname}</span>
            <span className="text-white font-bold">:</span>
            <span className="text-gray-400">~</span>
            <span className="text-white font-bold">[0]</span>
            <span className="text-gray-500 font-bold">#</span>
            <input
              type="text"
              value={commandInput}
              onChange={e => setCommandInput(e.target.value)}
              placeholder="введите команду (напр: help, genpass, free, df, ports, ips)..."
              className="flex-1 bg-transparent border-none outline-none text-emerald-300 placeholder-gray-600 font-mono text-xs pl-1"
            />
          </form>
        </div>
      </div>
    </div>
  );
};
