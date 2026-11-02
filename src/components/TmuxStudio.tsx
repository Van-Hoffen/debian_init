import React, { useState } from 'react';
import { Layers, Terminal, Copy, Check, Info, Shield, HelpCircle, Columns, Sparkles } from 'lucide-react';
import { TMUX_HOTKEYS } from '../data/dotfiles';

export const TmuxStudio: React.FC = () => {
  const [activeWindow, setActiveWindow] = useState<number>(1);
  const [isRootSession, setIsRootSession] = useState<boolean>(true);
  const [syncPanes, setSyncPanes] = useState<boolean>(false);
  const [showPopupHelp, setShowPopupHelp] = useState<boolean>(false);
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  // Pane layout simulation
  const [paneSplit, setPaneSplit] = useState<'single' | 'vertical' | 'horizontal' | 'quad'>('vertical');

  const windows = [
    { id: 1, title: 'bash', isRoot: true },
    { id: 2, title: 'htop', isRoot: false },
    { id: 3, title: 'logs', isRoot: false },
    { id: 4, title: 'nginx.conf', isRoot: true },
  ];

  const copyConfig = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedKey(id);
    setTimeout(() => setCopiedKey(null), 1800);
  };

  return (
    <div className="space-y-6">
      {/* Header Bar */}
      <div className="bg-[#131923] p-4 rounded-xl border border-gray-800 flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center space-x-3">
          <div className="p-2 bg-teal-500/10 text-teal-400 rounded-lg border border-teal-500/20">
            <Layers className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-base font-semibold text-white">Tmux Visual Studio & Dual-Status Bar Simulator</h2>
            <p className="text-xs text-gray-400">
              Визуализация двухуровневого статус-бара, цветового выделения ROOT и горячих клавиш из <span className="text-teal-400 font-mono">~/.tmux.conf</span>
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setIsRootSession(!isRootSession)}
            className={`px-3 py-1.5 rounded-lg text-xs font-mono font-bold transition-all border ${
              isRootSession
                ? 'bg-red-500/20 text-red-400 border-red-500/40 shadow-sm'
                : 'bg-teal-500/20 text-teal-300 border-teal-500/40'
            }`}
          >
            {isRootSession ? 'СЕССИЯ: ROOT' : 'СЕССИЯ: USER'}
          </button>

          <button
            onClick={() => setSyncPanes(!syncPanes)}
            className={`px-3 py-1.5 rounded-lg text-xs font-mono font-medium transition-colors border ${
              syncPanes
                ? 'bg-amber-500/20 text-amber-300 border-amber-500/40'
                : 'bg-gray-800 hover:bg-gray-700 text-gray-400 border-gray-700'
            }`}
          >
            {syncPanes ? '⚡SYNC: ON (Ctrl+a S)' : 'Sync: OFF'}
          </button>

          <button
            onClick={() => setShowPopupHelp(true)}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-800 hover:bg-gray-700 text-gray-200 rounded-lg text-xs font-medium border border-gray-700 transition-colors"
          >
            <HelpCircle className="w-3.5 h-3.5 text-teal-400" />
            <span>Hotkeys (Ctrl+a h)</span>
          </button>
        </div>
      </div>

      {/* Pane Layout Switcher */}
      <div className="flex items-center gap-2 text-xs">
        <span className="text-gray-400 font-medium">Раскладка панелей:</span>
        <button
          onClick={() => setPaneSplit('single')}
          className={`px-2.5 py-1 rounded border ${
            paneSplit === 'single' ? 'bg-teal-700/30 text-teal-300 border-teal-500/50' : 'bg-gray-800 text-gray-400 border-gray-700'
          }`}
        >
          Одиночная
        </button>
        <button
          onClick={() => setPaneSplit('vertical')}
          className={`px-2.5 py-1 rounded border ${
            paneSplit === 'vertical' ? 'bg-teal-700/30 text-teal-300 border-teal-500/50' : 'bg-gray-800 text-gray-400 border-gray-700'
          }`}
        >
          Вертикальный сплит (Ctrl+a =)
        </button>
        <button
          onClick={() => setPaneSplit('horizontal')}
          className={`px-2.5 py-1 rounded border ${
            paneSplit === 'horizontal' ? 'bg-teal-700/30 text-teal-300 border-teal-500/50' : 'bg-gray-800 text-gray-400 border-gray-700'
          }`}
        >
          Горизонтальный сплит (Ctrl+a -)
        </button>
        <button
          onClick={() => setPaneSplit('quad')}
          className={`px-2.5 py-1 rounded border ${
            paneSplit === 'quad' ? 'bg-teal-700/30 text-teal-300 border-teal-500/50' : 'bg-gray-800 text-gray-400 border-gray-700'
          }`}
        >
          4 панели (сетка 2x2)
        </button>
      </div>

      {/* Virtual Tmux Terminal Frame */}
      <div className="rounded-xl overflow-hidden border border-[#30363d] bg-[#161a22] shadow-2xl flex flex-col h-[460px]">
        {/* Pane Content Area */}
        <div className="flex-1 p-3 overflow-hidden font-mono text-xs text-gray-300 flex flex-col">
          {paneSplit === 'single' && (
            <div className="flex-1 bg-[#0d1117] rounded-lg p-3 border border-gray-800 flex flex-col justify-between">
              <div>
                <div className="text-gray-500 text-[11px] pb-2 border-b border-gray-800/60 flex items-center justify-between">
                  <span>Pane 1 (активна) • /root</span>
                  <span className="text-emerald-400">pid: 24190</span>
                </div>
                <div className="mt-3 text-emerald-400 font-semibold">$ apt update && apt upgrade -y</div>
                <div className="text-gray-400 mt-1">Reading package lists... Done</div>
                <div className="text-gray-400">Building dependency tree... Done</div>
                <div className="text-emerald-400 mt-2">All packages are up to date.</div>
              </div>
              <div className="text-gray-500 text-[11px]">$ _</div>
            </div>
          )}

          {paneSplit === 'vertical' && (
            <div className="flex-1 grid grid-cols-2 gap-2 h-full">
              <div className="bg-[#0d1117] rounded-lg p-3 border border-teal-600/50 flex flex-col justify-between">
                <div>
                  <div className="text-teal-400 text-[11px] pb-2 border-b border-gray-800 flex items-center justify-between">
                    <span>Pane 1 (активна) • /etc/nginx</span>
                    <span className="text-teal-400">vim nginx.conf</span>
                  </div>
                  <div className="mt-2 text-blue-300">server &#123;</div>
                  <div className="text-gray-400 pl-4">listen 80 default_server;</div>
                  <div className="text-gray-400 pl-4">server_name _;</div>
                  <div className="text-gray-400 pl-4">return 301 https://$host$request_uri;</div>
                  <div className="text-blue-300">&#125;</div>
                </div>
                <div className="text-gray-500 text-[11px]">"nginx.conf" 48L, 1290B</div>
              </div>

              <div className="bg-[#0d1117] rounded-lg p-3 border border-gray-800 flex flex-col justify-between">
                <div>
                  <div className="text-gray-500 text-[11px] pb-2 border-b border-gray-800 flex items-center justify-between">
                    <span>Pane 2 • /var/log/nginx</span>
                    <span className="text-gray-400">tail -f access.log</span>
                  </div>
                  <div className="mt-2 text-gray-400 text-[11px] space-y-1">
                    <div>10.5.12.44 - - [01/Nov/2026:22:18:02] "GET / HTTP/2.0" 200 4521</div>
                    <div>10.5.12.44 - - [01/Nov/2026:22:18:03] "GET /style.css HTTP/2.0" 304 0</div>
                    <div>172.16.2.10 - - [01/Nov/2026:22:18:10] "POST /api/auth HTTP/1.1" 200 84</div>
                  </div>
                </div>
                <div className="text-gray-500 text-[11px]">listening on live stream...</div>
              </div>
            </div>
          )}

          {paneSplit === 'horizontal' && (
            <div className="flex-1 grid grid-rows-2 gap-2 h-full">
              <div className="bg-[#0d1117] rounded-lg p-3 border border-teal-600/50 flex flex-col justify-between">
                <div className="text-teal-400 text-[11px] pb-1 border-b border-gray-800 flex justify-between">
                  <span>Pane 1 (активна) • /root</span>
                  <span className="text-teal-300">htop</span>
                </div>
                <div className="text-gray-400 text-xs">Tasks: 84 total, 2 running; Load: 0.42, 0.58, 0.61</div>
              </div>
              <div className="bg-[#0d1117] rounded-lg p-3 border border-gray-800 flex flex-col justify-between">
                <div className="text-gray-500 text-[11px] pb-1 border-b border-gray-800 flex justify-between">
                  <span>Pane 2 • /var/log</span>
                  <span className="text-gray-400">journalctl -f</span>
                </div>
                <div className="text-emerald-400 text-xs">systemd[1]: Started Proxmox VE replication runner.</div>
              </div>
            </div>
          )}

          {paneSplit === 'quad' && (
            <div className="flex-1 grid grid-cols-2 grid-rows-2 gap-2 h-full">
              {[1, 2, 3, 4].map(idx => (
                <div key={idx} className={`bg-[#0d1117] rounded-lg p-2.5 border text-xs flex flex-col justify-between ${
                  idx === 1 ? 'border-teal-500' : 'border-gray-800'
                }`}>
                  <div className="text-gray-400 text-[11px] flex justify-between border-b border-gray-800/80 pb-1">
                    <span>Pane {idx}</span>
                    <span className="text-gray-500">pty/{idx}</span>
                  </div>
                  <div className="text-gray-400 text-[11px]">
                    {syncPanes ? (
                      <span className="text-amber-400 font-semibold">⚡ Синхронизация активна: ввод передается сюда</span>
                    ) : (
                      <span>Консоль #{idx} готова к командам</span>
                    )}
                  </div>
                  <div className="text-gray-600 text-[10px]">$ _</div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Tmux Status Line 1: Sessions & Window List (matching status 2 from .tmux.conf) */}
        <div className="bg-[#1c1b19] border-t border-[#30363d] px-2 py-1 text-xs font-mono flex items-center justify-between select-none">
          <div className="flex items-center space-x-1">
            {/* ROOT / USER Badge */}
            {isRootSession ? (
              <span className="bg-[#a81414] text-white px-2 py-0.5 font-bold rounded-sm text-[11px] mr-1 flex items-center gap-1">
                <span>ROOT:main</span>
                <span className="opacity-60 text-[9px]">▓▒░</span>
              </span>
            ) : (
              <span className="bg-[#01696f] text-white px-2 py-0.5 font-bold rounded-sm text-[11px] mr-1 flex items-center gap-1">
                <span>main</span>
                <span className="opacity-60 text-[9px]">▓▒░</span>
              </span>
            )}

            {/* Window Tabs (Alt+1..9) */}
            {windows.map(win => {
              const isActive = activeWindow === win.id;
              return (
                <button
                  key={win.id}
                  onClick={() => setActiveWindow(win.id)}
                  className={`px-2 py-0.5 rounded-sm text-xs font-mono transition-colors flex items-center gap-1 ${
                    isActive
                      ? win.isRoot
                        ? 'bg-[#a81414] text-white font-bold'
                        : 'bg-[#01696f] text-white font-bold'
                      : win.isRoot
                      ? 'text-red-400 hover:bg-gray-800'
                      : 'text-gray-400 hover:bg-gray-800'
                  }`}
                >
                  <span>{win.id}:{win.title}</span>
                  {isActive && <span className="text-[10px] opacity-75">*</span>}
                </button>
              );
            })}
          </div>

          <div className="text-[11px] text-gray-500 font-mono hidden sm:block">
            Переключение: <kbd className="bg-gray-800 px-1 rounded text-gray-300">Alt+1-9</kbd>
          </div>
        </div>

        {/* Tmux Status Line 2: Telemetry Bar (matching status-format[1] from .tmux.conf) */}
        <div className="bg-[#24221f] border-t border-[#33312c] px-3 py-1 text-[11px] font-mono text-gray-300 flex flex-wrap items-center justify-between select-none">
          <div className="flex items-center space-x-2">
            <span className="font-bold text-gray-200">deb-srv-core01</span>
            <span className="text-gray-600">│</span>
            <span className="text-gray-400">/root/debian_setup</span>
            {syncPanes && (
              <>
                <span className="text-gray-600">│</span>
                <span className="text-amber-400 font-bold flex items-center gap-0.5 animate-pulse">
                  ⚡SYNC
                </span>
              </>
            )}
          </div>

          <div className="flex items-center space-x-3 text-gray-400">
            <div>
              <span className="text-gray-500">CPU: </span>
              <span className="text-emerald-400 font-semibold">14%</span>
            </div>
            <div>
              <span className="text-gray-500">RAM: </span>
              <span className="text-emerald-400 font-semibold">7420MB/16384MB</span>
            </div>
            <span className="text-gray-600">│</span>
            <div>
              <span className="text-amber-300">0.42 0.58 0.61</span>
            </div>
            <span className="text-gray-600">│</span>
            <div className="text-gray-300 font-bold">
              {new Date().toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' })}
            </div>
          </div>
        </div>
      </div>

      {/* Hotkeys Quick Reference Table */}
      <div className="bg-[#10151f] p-4 rounded-xl border border-gray-800 space-y-3">
        <h3 className="text-xs font-semibold uppercase tracking-wider text-gray-400 flex items-center gap-2">
          <Terminal className="w-4 h-4 text-teal-400" />
          <span>Таблица горячих клавиш tmux (Префикс: Ctrl+a)</span>
        </h3>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-xs">
          {TMUX_HOTKEYS.map((hk, idx) => (
            <div
              key={idx}
              className="p-2.5 bg-gray-900/60 rounded-lg border border-gray-800/80 hover:border-gray-700 flex items-center justify-between gap-2"
            >
              <div className="flex items-center gap-2">
                <span className="font-mono font-bold text-teal-300 bg-teal-500/10 px-2 py-0.5 rounded border border-teal-500/20">
                  {hk.prefix === 'None' ? '' : `${hk.prefix} `}{hk.key}
                </span>
                <span className="text-gray-300 text-xs">{hk.desc}</span>
              </div>
              <span className="text-[10px] font-mono text-gray-500 truncate max-w-[120px]">{hk.action}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Popup Cheatsheet Modal (Ctrl+a h simulator) */}
      {showPopupHelp && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-[#161b22] border border-teal-500/50 rounded-xl shadow-2xl max-w-lg w-full overflow-hidden font-mono text-xs text-gray-300 animate-in fade-in zoom-in-95 duration-150">
            <div className="bg-[#01696f] text-white px-4 py-2 font-bold flex items-center justify-between">
              <span>Hotkeys Cheatsheet (Ctrl+a h)</span>
              <button
                onClick={() => setShowPopupHelp(false)}
                className="hover:opacity-75 text-sm"
              >
                ✕
              </button>
            </div>
            <div className="p-4 space-y-3 max-h-[70vh] overflow-y-auto">
              <div className="text-teal-300 font-bold border-b border-gray-700 pb-1">
                ПРЕФИКС (Prf): Ctrl+a
              </div>
              
              <div className="space-y-1">
                <div className="text-amber-400 font-semibold">── Панели ──</div>
                <div className="pl-2 space-y-0.5 text-gray-300">
                  <div><span className="text-teal-300">Prf+=</span>   Разделить вертикально (|)</div>
                  <div><span className="text-teal-300">Prf+-</span>   Разделить горизонтально (-)</div>
                  <div><span className="text-teal-300">Prf+x</span>   Закрыть панель</div>
                  <div><span className="text-teal-300">Alt+e</span>   Закрыть панель без подтверждения</div>
                  <div><span className="text-teal-300">Prf+z</span>   Развернуть панель на весь экран</div>
                  <div><span className="text-teal-300">Prf+S</span>   Синхронизация ввода во все панели (⚡SYNC)</div>
                </div>
              </div>

              <div className="space-y-1">
                <div className="text-amber-400 font-semibold">── Окна ──</div>
                <div className="pl-2 space-y-0.5 text-gray-300">
                  <div><span className="text-teal-300">Prf+c</span>   Новое окно</div>
                  <div><span className="text-teal-300">Prf+,</span>   Переименовать окно</div>
                  <div><span className="text-teal-300">Alt+1-9</span> Быстрое переключение / создание окна</div>
                  <div><span className="text-teal-300">Alt+q</span>   Закрыть окно (с подтверждением)</div>
                </div>
              </div>

              <div className="space-y-1">
                <div className="text-amber-400 font-semibold">── Сессии & Прочее ──</div>
                <div className="pl-2 space-y-0.5 text-gray-300">
                  <div><span className="text-teal-300">Prf+d</span>   Отключиться (сессия остаётся в фоне)</div>
                  <div><span className="text-teal-300">Prf+s</span>   Список сессий</div>
                  <div><span className="text-teal-300">Prf+r</span>   Перезагрузить ~/.tmux.conf</div>
                  <div><span className="text-teal-300">Prf+[</span>   Режим скролла / vi-копирование</div>
                  <div><span className="text-teal-300">Prf+]</span>   Вставить из буфера</div>
                </div>
              </div>
            </div>
            <div className="bg-[#0d1117] px-4 py-2 text-right border-t border-gray-800">
              <button
                onClick={() => setShowPopupHelp(false)}
                className="px-3 py-1 bg-gray-800 hover:bg-gray-700 text-gray-200 text-xs rounded transition-colors"
              >
                Закрыть (Esc)
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
