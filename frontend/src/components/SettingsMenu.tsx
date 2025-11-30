import { FiX, FiSettings } from 'react-icons/fi';
import { INSTRUMENTS, type Instrument } from '@/types/catalog';

interface SettingsMenuProps {
  isOpen: boolean;
  onClose: () => void;
  currentInstrument: Instrument;
  onInstrumentChange: (instrument: Instrument) => void;
  onLogout?: () => void;
  onOpenAbout?: () => void;
}

export function SettingsMenu({ isOpen, onClose, currentInstrument, onInstrumentChange, onLogout, onOpenAbout }: SettingsMenuProps) {
  if (!isOpen) return null;

  // Get build timestamp in PST
  const buildDate = new Date().toLocaleString('en-US', {
    timeZone: 'America/Los_Angeles',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });

  return (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/50 z-40 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Menu Panel */}
      <div className="fixed top-0 right-0 h-full w-80 bg-gray-900/95 backdrop-blur-lg z-50 shadow-2xl border-l border-white/10">
        <div className="flex flex-col h-full">
          {/* Header */}
          <div className="flex items-center justify-between p-6 border-b border-white/10">
            <div className="flex items-center gap-2">
              <FiSettings className="text-blue-400 text-xl" />
              <h2 className="text-xl font-semibold text-white">Settings</h2>
            </div>
            <button
              onClick={onClose}
              className="p-2 hover:bg-white/10 rounded-mcm transition-colors"
              aria-label="Close settings"
            >
              <FiX className="text-white text-xl" />
            </button>
          </div>

          {/* Content */}
          <div className="flex-1 overflow-y-auto p-6 space-y-6">
            {/* Display Settings */}
            <section>
              <h3 className="text-sm font-semibold text-gray-400 uppercase tracking-wide mb-3">
                Display
              </h3>
              <div className="space-y-2">
                <label className="block text-white text-sm">
                  Song List Density
                  <select
                    className="w-full mt-1.5 px-3 py-2 bg-black/30 border border-white/20 rounded-mcm text-white text-sm focus:outline-none focus:ring-1 focus:ring-blue-400"
                    disabled
                  >
                    <option>Comfortable (Default)</option>
                    <option>Dense (Coming Soon)</option>
                  </select>
                </label>
              </div>
            </section>

            {/* Help */}
            <section>
              <h3 className="text-sm font-semibold text-gray-400 uppercase tracking-wide mb-3">
                Help
              </h3>
              <div className="bg-black/20 rounded-mcm border border-white/10 p-4">
                <h4 className="text-white font-medium mb-3 text-sm">Keyboard Shortcuts</h4>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between text-gray-300">
                    <span>Navigate pages</span>
                    <kbd className="px-2 py-1 bg-white/10 rounded-mcm text-xs">Arrow Keys</kbd>
                  </div>
                  <div className="flex justify-between text-gray-300">
                    <span>Close viewer</span>
                    <kbd className="px-2 py-1 bg-white/10 rounded-mcm text-xs">ESC</kbd>
                  </div>
                  <div className="flex justify-between text-gray-300">
                    <span>Fullscreen</span>
                    <kbd className="px-2 py-1 bg-white/10 rounded-mcm text-xs">F</kbd>
                  </div>
                  <div className="flex justify-between text-gray-300">
                    <span>Open PDF (search)</span>
                    <kbd className="px-2 py-1 bg-white/10 rounded-mcm text-xs">Enter</kbd>
                  </div>
                </div>
              </div>
            </section>

            {/* Instrument */}
            <section>
              <h3 className="text-sm font-semibold text-gray-400 uppercase tracking-wide mb-3">
                My Instrument
              </h3>
              <div className="space-y-4">
                <label className="block">
                  <span className="text-gray-500 text-xs block mb-1.5">
                    PDFs will be transposed for your instrument
                  </span>
                  <select
                    value={currentInstrument.id}
                    onChange={(e) => {
                      const inst = INSTRUMENTS.find(i => i.id === e.target.value);
                      if (inst) onInstrumentChange(inst);
                    }}
                    className="w-full px-3 py-2.5 bg-black/30 border border-white/20 rounded-mcm text-white text-sm focus:outline-none focus:ring-1 focus:ring-blue-400 cursor-pointer"
                  >
                    {INSTRUMENTS.map((inst) => (
                      <option key={inst.id} value={inst.id}>
                        {inst.label} ({inst.transposition}{inst.clef === 'bass' ? ', bass clef' : ''})
                      </option>
                    ))}
                  </select>
                </label>

                {onLogout && (
                  <button
                    onClick={() => {
                      onLogout();
                      onClose();
                    }}
                    className="w-full px-4 py-2.5 bg-red-500/20 hover:bg-red-500/30 border border-red-500/30 rounded-mcm text-red-300 text-sm text-left transition-colors"
                  >
                    Log out
                  </button>
                )}
              </div>
            </section>
          </div>

          {/* Footer - About */}
          <div className="p-6 border-t border-white/10 bg-black/20">
            <h3 className="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-2">
              About
            </h3>
            <div className="text-sm space-y-2">
              <p className="text-white font-medium">Jazz Picker v2.1</p>
              <p className="text-gray-500 text-xs">
                Built: {buildDate} PST
              </p>
              {onOpenAbout && (
                <button
                  onClick={() => {
                    onOpenAbout();
                    onClose();
                  }}
                  className="text-blue-400 hover:text-blue-300 text-sm underline underline-offset-2"
                >
                  About & Install Guide
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
