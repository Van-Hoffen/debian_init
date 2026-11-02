import React, { useState } from 'react';
import { Search, Terminal, Copy, Check, Key, Shield, ArrowRight, FolderSearch, RefreshCw, Zap } from 'lucide-react';
import { REPO_ALIASES, AliasItem } from '../data/dotfiles';

export const BashAliasesExplorer: React.FC = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [copiedName, setCopiedName] = useState<string | null>(null);

  // Interactive genpass state
  const [genPassLen, setGenPassLen] = useState(20);
  const [generatedPassword, setGeneratedPassword] = useState('');
  const [passCopied, setPassCopied] = useState(false);

  // Interactive chkport state
  const [portHost, setPortHost] = useState('127.0.0.1');
  const [portNum, setPortNum] = useState('22');
  const [portResult, setPortResult] = useState<string | null>(null);

  // Interactive extract state
  const [testArchive, setTestArchive] = useState('backup_2026.tar.gz');

  const categories = ['All', 'Functions', 'Navigation', 'Files', 'System', 'Git', 'Updates', 'Network', 'Configs'];

  const filteredAliases = REPO_ALIASES.filter(item => {
    const matchesCat = selectedCategory === 'All' || item.category === selectedCategory;
    const matchesSearch =
      item.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.command.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCat && matchesSearch;
  });

  const copyText = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedName(id);
    setTimeout(() => setCopiedName(null), 1800);
  };

  const handleGeneratePassword = () => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=[]{}';
    let res = '';
    const array = new Uint32Array(genPassLen);
    window.crypto.getRandomValues(array);
    for (let i = 0; i < genPassLen; i++) {
      res += chars[array[i] % chars.length];
    }
    setGeneratedPassword(res);
  };

  const handleCheckPort = () => {
    // Simulated check
    const openPorts = ['22', '80', '443', '5432', '6379'];
    if (openPorts.includes(portNum.trim())) {
      setPortResult(`Открыт (TCP handshake успешен для ${portHost}:${portNum})`);
    } else {
      setPortResult(`Закрыт или фильтруется (Connection refused / Timeout)`);
    }
  };

  const getExtractPreview = () => {
    const lower = testArchive.toLowerCase();
    if (lower.endsWith('.tar.gz') || lower.endsWith('.tgz')) return `tar -xzvf ${testArchive}`;
    if (lower.endsWith('.tar.bz2') || lower.endsWith('.tbz2')) return `tar -xjvf ${testArchive}`;
    if (lower.endsWith('.tar.xz')) return `tar -xJvf ${testArchive}`;
    if (lower.endsWith('.zip')) return `unzip ${testArchive}`;
    if (lower.endsWith('.7z')) return `7z x ${testArchive}`;
    if (lower.endsWith('.rar')) return `unrar x ${testArchive}`;
    if (lower.endsWith('.gz')) return `gunzip ${testArchive}`;
    if (lower.endsWith('.bz2')) return `bunzip2 ${testArchive}`;
    return `Неизвестный формат архива: ${testArchive}`;
  };

  return (
    <div className="space-y-6">
      {/* Header bar */}
      <div className="bg-[#131923] p-4 rounded-xl border border-gray-800 flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center space-x-3">
          <div className="p-2 bg-purple-500/10 text-purple-400 rounded-lg border border-purple-500/20">
            <Zap className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-base font-semibold text-white">Bash Aliases & Shell Functions Explorer</h2>
            <p className="text-xs text-gray-400">
              Коллекция из 40+ проверенных системных алиасов и функций из <span className="text-blue-400 font-mono">/etc/bash/.bash_aliases</span>
            </p>
          </div>
        </div>

        <div className="text-xs text-gray-400 font-mono bg-[#0d1117] px-3 py-1.5 rounded-lg border border-gray-800">
          Всего в репозитории: <span className="text-purple-400 font-bold">{REPO_ALIASES.length}</span>
        </div>
      </div>

      {/* Interactive Tool Sandbox Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* genpass interactive tool */}
        <div className="bg-[#10151f] p-4 rounded-xl border border-gray-800 space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-xs font-semibold text-emerald-400 font-mono">
              <Key className="w-4 h-4" />
              <span>genpass() Sandbox</span>
            </div>
            <span className="text-[11px] text-gray-500 font-mono">{genPassLen} символов</span>
          </div>
          <p className="text-xs text-gray-400 leading-normal">
            Интерактивный генератор из функции <code className="text-emerald-400 font-mono">genpass</code>
          </p>
          <div className="flex items-center gap-2">
            <input
              type="range"
              min="8"
              max="48"
              value={genPassLen}
              onChange={e => setGenPassLen(parseInt(e.target.value))}
              className="flex-1 accent-emerald-500"
            />
            <button
              onClick={handleGeneratePassword}
              className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-medium rounded-lg transition-colors flex items-center gap-1"
            >
              <RefreshCw className="w-3 h-3" />
              <span>Создать</span>
            </button>
          </div>
          {generatedPassword && (
            <div className="flex items-center justify-between bg-[#0d1117] p-2 rounded border border-gray-700 text-xs font-mono text-emerald-300">
              <span className="truncate pr-2">{generatedPassword}</span>
              <button
                onClick={() => {
                  navigator.clipboard.writeText(generatedPassword);
                  setPassCopied(true);
                  setTimeout(() => setPassCopied(false), 1800);
                }}
                className="hover:text-white text-gray-400"
              >
                {passCopied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
              </button>
            </div>
          )}
        </div>

        {/* chkport interactive tool */}
        <div className="bg-[#10151f] p-4 rounded-xl border border-gray-800 space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-xs font-semibold text-blue-400 font-mono">
              <Shield className="w-4 h-4" />
              <span>chkport() Simulator</span>
            </div>
            <span className="text-[11px] text-gray-500">/dev/tcp check</span>
          </div>
          <p className="text-xs text-gray-400 leading-normal">
            Проверка портов без nmap: <code className="text-blue-400 font-mono">chkport &lt;ip&gt; &lt;port&gt;</code>
          </p>
          <div className="flex gap-2">
            <input
              type="text"
              value={portHost}
              onChange={e => setPortHost(e.target.value)}
              className="w-1/2 bg-[#0d1117] border border-gray-700 rounded px-2 py-1 text-xs text-gray-200 font-mono"
              placeholder="127.0.0.1"
            />
            <input
              type="text"
              value={portNum}
              onChange={e => setPortNum(e.target.value)}
              className="w-20 bg-[#0d1117] border border-gray-700 rounded px-2 py-1 text-xs text-gray-200 font-mono"
              placeholder="22"
            />
            <button
              onClick={handleCheckPort}
              className="px-2.5 py-1 bg-blue-600 hover:bg-blue-500 text-white text-xs font-medium rounded-lg transition-colors"
            >
              Тест
            </button>
          </div>
          {portResult && (
            <div className={`p-2 rounded border text-xs font-mono ${
              portResult.startsWith('Открыт')
                ? 'bg-emerald-950/40 border-emerald-800/60 text-emerald-300'
                : 'bg-red-950/40 border-red-800/60 text-red-300'
            }`}>
              {portResult}
            </div>
          )}
        </div>

        {/* extract() previewer */}
        <div className="bg-[#10151f] p-4 rounded-xl border border-gray-800 space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-xs font-semibold text-amber-400 font-mono">
              <FolderSearch className="w-4 h-4" />
              <span>extract() Logic Test</span>
            </div>
            <span className="text-[11px] text-gray-500 font-mono">auto-unpack</span>
          </div>
          <p className="text-xs text-gray-400 leading-normal">
            Универсальная распаковка: авто-выбор команды по расширению
          </p>
          <input
            type="text"
            value={testArchive}
            onChange={e => setTestArchive(e.target.value)}
            className="w-full bg-[#0d1117] border border-gray-700 rounded px-2.5 py-1 text-xs text-gray-200 font-mono"
            placeholder="archive.tar.xz"
          />
          <div className="p-2 bg-[#0d1117] rounded border border-gray-800 text-xs font-mono text-amber-300 flex items-center justify-between">
            <span className="truncate pr-2">$ {getExtractPreview()}</span>
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="flex flex-wrap items-center justify-between gap-3 bg-[#10151f] p-3 rounded-xl border border-gray-800">
        <div className="flex flex-wrap gap-1.5">
          {categories.map(cat => (
            <button
              key={cat}
              onClick={() => setSelectedCategory(cat)}
              className={`px-3 py-1 rounded-lg text-xs font-medium transition-colors ${
                selectedCategory === cat
                  ? 'bg-purple-600 text-white'
                  : 'bg-gray-800/70 hover:bg-gray-700 text-gray-300'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>

        <div className="relative w-full sm:w-64">
          <Search className="w-3.5 h-3.5 absolute left-3 top-2.5 text-gray-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            placeholder="Поиск по имени или описанию..."
            className="w-full pl-9 pr-3 py-1.5 bg-[#0d1117] border border-gray-700 rounded-lg text-xs text-gray-200 placeholder-gray-500 outline-none focus:border-purple-500"
          />
        </div>
      </div>

      {/* Aliases Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
        {filteredAliases.map(item => (
          <div
            key={item.name}
            className="bg-[#10151f] p-4 rounded-xl border border-gray-800/80 hover:border-gray-700 transition-all flex flex-col justify-between group"
          >
            <div>
              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-2">
                  <span className="font-mono text-sm font-bold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded border border-emerald-500/20">
                    {item.name}
                  </span>
                  <span className={`text-[10px] px-2 py-0.5 rounded-full font-mono font-medium ${
                    item.type === 'function'
                      ? 'bg-purple-500/20 text-purple-300 border border-purple-500/30'
                      : 'bg-blue-500/20 text-blue-300 border border-blue-500/30'
                  }`}>
                    {item.type}
                  </span>
                  <span className="text-[11px] text-gray-500">{item.category}</span>
                </div>

                <button
                  onClick={() => copyText(item.command, item.name)}
                  className="opacity-60 group-hover:opacity-100 hover:text-white text-gray-400 p-1 transition-opacity"
                  title="Копировать команду"
                >
                  {copiedName === item.name ? (
                    <Check className="w-3.5 h-3.5 text-emerald-400" />
                  ) : (
                    <Copy className="w-3.5 h-3.5" />
                  )}
                </button>
              </div>

              <p className="text-xs text-gray-300 mt-2 font-sans leading-relaxed">
                {item.description}
              </p>

              {item.usageExample && (
                <div className="mt-2 text-[11px] text-gray-500 font-mono flex items-center gap-1.5">
                  <span className="text-gray-400">Пример:</span>
                  <code className="text-amber-300 bg-gray-900 px-1.5 py-0.5 rounded border border-gray-800">
                    {item.usageExample}
                  </code>
                </div>
              )}
            </div>

            {/* Command snippet */}
            <div className="mt-3 pt-2 border-t border-gray-800/70">
              <pre className="text-xs font-mono text-gray-400 overflow-x-auto bg-[#0d1117] p-2 rounded border border-gray-800">
                <code>{item.command}</code>
              </pre>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
