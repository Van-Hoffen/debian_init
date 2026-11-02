import React, { useState } from 'react';
import { Server, Check, Copy, Plus, Trash2, Filter, FileText, Download } from 'lucide-react';

interface ServicesManagerProps {
  services: { name: string; category: string; description: string; defaultActive: boolean }[];
  onToggleService: (name: string) => void;
  serverInfoText: string;
  onUpdateServerInfo: (text: string) => void;
}

export const ServicesManager: React.FC<ServicesManagerProps> = ({
  services,
  onToggleService,
  serverInfoText,
  onUpdateServerInfo,
}) => {
  const [selectedCat, setSelectedCat] = useState<string>('All');
  const [newSvcName, setNewSvcName] = useState('');
  const [newSvcDesc, setNewSvcDesc] = useState('');
  const [newSvcCat, setNewSvcCat] = useState('Web & Proxies');
  const [copiedChecklist, setCopiedChecklist] = useState(false);
  const [copiedInfo, setCopiedInfo] = useState(false);

  const categories = ['All', 'Web & Proxies', 'Databases', 'Security & System', 'Containers', 'Proxmox VE', 'Monitoring', 'Mail', '1C:Enterprise'];

  const filtered = services.filter(s => selectedCat === 'All' || s.category === selectedCat);

  const generateServicesCheckContent = () => {
    let out = `# ==============================================================================\n# СПИСОК ОТСЛЕЖИВАЕМЫХ СЕРВИСОВ ДЛЯ WELCOME SCREEN (/etc/bash/.services_check)\n# ==============================================================================\n\n`;
    services
      .filter(s => s.defaultActive)
      .forEach(s => {
        out += `${s.name.padEnd(20, ' ')} # ${s.description}\n`;
      });
    return out;
  };

  const downloadFile = (filename: string, content: string) => {
    const el = document.createElement('a');
    el.href = URL.createObjectURL(new Blob([content], { type: 'text/plain' }));
    el.download = filename;
    document.body.appendChild(el);
    el.click();
    document.body.removeChild(el);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-[#131923] p-4 rounded-xl border border-gray-800 flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center space-x-3">
          <div className="p-2 bg-blue-500/10 text-blue-400 rounded-lg border border-blue-500/20">
            <Server className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-base font-semibold text-white">Services & Server Info Manager</h2>
            <p className="text-xs text-gray-400">
              Управление списками отслеживаемых служб <span className="text-blue-400 font-mono">.services_check</span> и описанием хоста <span className="text-blue-400 font-mono">.server_info</span>
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => {
              navigator.clipboard.writeText(generateServicesCheckContent());
              setCopiedChecklist(true);
              setTimeout(() => setCopiedChecklist(false), 1800);
            }}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-800 hover:bg-gray-700 text-gray-300 rounded-lg text-xs font-medium border border-gray-700 transition-colors"
          >
            {copiedChecklist ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
            <span>Скопировать .services_check</span>
          </button>

          <button
            onClick={() => downloadFile('.services_check', generateServicesCheckContent())}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-blue-600 hover:bg-blue-500 text-white rounded-lg text-xs font-medium transition-colors"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Скачать</span>
          </button>
        </div>
      </div>

      {/* Server Info Editor (.server_info) */}
      <div className="bg-[#10151f] p-4 rounded-xl border border-gray-800 space-y-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <FileText className="w-4 h-4 text-emerald-400" />
            <h3 className="text-xs font-semibold uppercase tracking-wider text-gray-300">
              Описание сервера (/etc/bash/.server_info)
            </h3>
          </div>
          <span className="text-[11px] text-gray-500">Отображается в секции 9 экрана приветствия MOTD</span>
        </div>

        <textarea
          value={serverInfoText}
          onChange={e => onUpdateServerInfo(e.target.value)}
          rows={3}
          className="w-full bg-[#0d1117] border border-gray-700 rounded-lg p-3 text-xs text-gray-200 font-mono outline-none focus:border-emerald-500 leading-relaxed"
          placeholder="Назначение сервера, ответственный системный администратор, регламенты обслуживания..."
        />
      </div>

      {/* Category filter */}
      <div className="flex flex-wrap items-center justify-between gap-3 bg-[#10151f] p-3 rounded-xl border border-gray-800">
        <div className="flex flex-wrap gap-1.5">
          {categories.map(cat => (
            <button
              key={cat}
              onClick={() => setSelectedCat(cat)}
              className={`px-3 py-1 rounded-lg text-xs font-medium transition-colors ${
                selectedCat === cat
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-800/70 hover:bg-gray-700 text-gray-300'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>

        <div className="text-xs text-gray-400 font-mono">
          Активно в MOTD: <span className="text-emerald-400 font-bold">{services.filter(s => s.defaultActive).length}</span> из {services.length}
        </div>
      </div>

      {/* Services Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
        {filtered.map(svc => (
          <div
            key={svc.name}
            onClick={() => onToggleService(svc.name)}
            className={`p-3 rounded-xl border cursor-pointer transition-all flex items-center justify-between gap-3 select-none ${
              svc.defaultActive
                ? 'bg-emerald-950/20 border-emerald-500/40 hover:border-emerald-500/70'
                : 'bg-[#10151f] border-gray-800 hover:border-gray-700 opacity-60 hover:opacity-100'
            }`}
          >
            <div className="flex items-center gap-3">
              <span className={`w-3 h-3 rounded-full flex items-center justify-center border ${
                svc.defaultActive
                  ? 'bg-emerald-500 border-emerald-400 text-black'
                  : 'bg-transparent border-gray-600'
              }`}>
                {svc.defaultActive && <Check className="w-2.5 h-2.5 stroke-[3]" />}
              </span>
              <div>
                <div className="font-mono text-xs font-bold text-gray-200">{svc.name}</div>
                <div className="text-[11px] text-gray-400 truncate max-w-[190px]">{svc.description}</div>
              </div>
            </div>

            <span className="text-[10px] font-mono text-gray-500 bg-gray-900/80 px-2 py-0.5 rounded border border-gray-800">
              {svc.category}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};
