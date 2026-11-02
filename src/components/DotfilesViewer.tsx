import React, { useState } from 'react';
import { FileCode, Download, Copy, Check, Search, Folder, FileText, ChevronRight } from 'lucide-react';

interface FileEntry {
  path: string;
  category: string;
  description: string;
  content: string;
}

interface DotfilesViewerProps {
  files: FileEntry[];
}

export const DotfilesViewer: React.FC<DotfilesViewerProps> = ({ files }) => {
  const [selectedFile, setSelectedFile] = useState<FileEntry>(files[0]);
  const [searchQuery, setSearchQuery] = useState('');
  const [copied, setCopied] = useState(false);

  const filteredFiles = files.filter(f =>
    f.path.toLowerCase().includes(searchQuery.toLowerCase()) ||
    f.description.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const copyContent = () => {
    navigator.clipboard.writeText(selectedFile.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const downloadCurrent = () => {
    const filename = selectedFile.path.split('/').pop() || 'dotfile';
    const blob = new Blob([selectedFile.content], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-[#131923] p-4 rounded-xl border border-gray-800 flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center space-x-3">
          <div className="p-2 bg-emerald-500/10 text-emerald-400 rounded-lg border border-emerald-500/20">
            <FileCode className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-base font-semibold text-white">Repository Dotfiles & Raw Sources</h2>
            <p className="text-xs text-gray-400">
              Исходные файлы репозитория <span className="text-emerald-400 font-mono">Van-Hoffen/debian_init</span> с подсветкой и выгрузкой
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={copyContent}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-800 hover:bg-gray-700 text-gray-200 rounded-lg text-xs font-medium border border-gray-700 transition-colors"
          >
            {copied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
            <span>Скопировать</span>
          </button>

          <button
            onClick={downloadCurrent}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg text-xs font-medium transition-colors"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Скачать файл</span>
          </button>
        </div>
      </div>

      {/* Main split: File list on left, content on right */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
        {/* Sidebar file tree */}
        <div className="lg:col-span-4 bg-[#10151f] p-3 rounded-xl border border-gray-800 flex flex-col space-y-3">
          <div className="relative">
            <Search className="w-3.5 h-3.5 absolute left-3 top-2.5 text-gray-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
              placeholder="Поиск файла..."
              className="w-full pl-9 pr-3 py-1.5 bg-[#0d1117] border border-gray-700 rounded-lg text-xs text-gray-200 placeholder-gray-500 outline-none focus:border-emerald-500"
            />
          </div>

          <div className="space-y-1 overflow-y-auto max-h-[550px] pr-1">
            {filteredFiles.map(file => {
              const isSelected = selectedFile.path === file.path;
              return (
                <button
                  key={file.path}
                  onClick={() => setSelectedFile(file)}
                  className={`w-full text-left p-2.5 rounded-lg border transition-all flex items-center justify-between text-xs ${
                    isSelected
                      ? 'bg-emerald-950/30 border-emerald-500/50 text-white shadow-sm'
                      : 'bg-gray-900/40 border-gray-800/80 hover:border-gray-700 text-gray-400 hover:text-gray-200'
                  }`}
                >
                  <div className="truncate pr-2">
                    <div className="font-mono font-medium text-xs text-gray-200 truncate">
                      {file.path}
                    </div>
                    <div className="text-[11px] text-gray-500 truncate mt-0.5">
                      {file.description}
                    </div>
                  </div>
                  <ChevronRight className={`w-3.5 h-3.5 shrink-0 ${isSelected ? 'text-emerald-400' : 'text-gray-600'}`} />
                </button>
              );
            })}
          </div>
        </div>

        {/* Content viewer */}
        <div className="lg:col-span-8 bg-[#0d1117] rounded-xl border border-gray-800 overflow-hidden flex flex-col shadow-lg">
          <div className="bg-[#161b22] px-4 py-3 border-b border-[#30363d] flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-400"></span>
              <span className="font-mono text-xs font-semibold text-gray-200">{selectedFile.path}</span>
              <span className="text-[11px] text-gray-500 font-mono">
                ({selectedFile.content.split('\n').length} строк)
              </span>
            </div>
            <span className="text-[11px] text-gray-400 bg-gray-800/80 px-2 py-0.5 rounded border border-gray-700">
              {selectedFile.category}
            </span>
          </div>

          <div className="p-4 overflow-x-auto max-h-[550px] text-xs font-mono text-gray-300">
            <pre className="leading-relaxed">
              {selectedFile.content.split('\n').map((line, idx) => (
                <div key={idx} className="flex hover:bg-gray-800/30 px-1 rounded">
                  <span className="w-10 text-gray-600 select-none text-right pr-4 font-mono text-[11px]">
                    {idx + 1}
                  </span>
                  <span className={line.startsWith('#') ? 'text-gray-500' : 'text-gray-300'}>
                    {line || ' '}
                  </span>
                </div>
              ))}
            </pre>
          </div>
        </div>
      </div>
    </div>
  );
};
