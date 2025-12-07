import { useState } from 'react';
import { INSTRUMENTS, type Instrument } from '@/types/catalog';

interface InstrumentPickerModalProps {
  currentInstrument: Instrument;
  onSelect: (instrument: Instrument) => void;
  onClose: () => void;
}

const instrumentGroups = [
  {
    label: 'Concert Pitch (C)',
    instruments: INSTRUMENTS.filter(i => i.transposition === 'C' && i.clef === 'treble'),
  },
  {
    label: 'Bb Instruments',
    instruments: INSTRUMENTS.filter(i => i.transposition === 'Bb'),
  },
  {
    label: 'Eb Instruments',
    instruments: INSTRUMENTS.filter(i => i.transposition === 'Eb'),
  },
  {
    label: 'Bass Clef',
    instruments: INSTRUMENTS.filter(i => i.clef === 'bass'),
  },
];

export function InstrumentPickerModal({ currentInstrument, onSelect, onClose }: InstrumentPickerModalProps) {
  const [selectedInstrument, setSelectedInstrument] = useState<Instrument>(currentInstrument);
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    if (selectedInstrument.id === currentInstrument.id) {
      onClose();
      return;
    }
    setSaving(true);
    onSelect(selectedInstrument);
  };

  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center p-4 z-50">
      <div className="bg-gray-800 rounded-xl max-w-md w-full max-h-[80vh] overflow-y-auto">
        <div className="p-4 border-b border-white/10 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-white">Change Instrument</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-white p-1"
          >
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div className="p-4 space-y-3">
          {instrumentGroups.map((group) => (
            <div key={group.label} className="bg-white/5 rounded-lg p-3 border border-white/10">
              <h3 className="text-xs font-medium text-gray-400 uppercase tracking-wide mb-2">
                {group.label}
              </h3>
              <div className="flex flex-wrap gap-2">
                {group.instruments.map((inst) => (
                  <button
                    key={inst.id}
                    onClick={() => setSelectedInstrument(inst)}
                    className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-all ${
                      selectedInstrument.id === inst.id
                        ? 'bg-blue-500 text-white border border-blue-400'
                        : 'bg-white/10 text-white border border-white/20 hover:bg-white/20'
                    }`}
                  >
                    {inst.label}
                  </button>
                ))}
              </div>
            </div>
          ))}
        </div>

        <div className="p-4 border-t border-white/10">
          <button
            onClick={handleSave}
            disabled={saving}
            className="w-full py-2 bg-blue-500 hover:bg-blue-600 disabled:bg-blue-500/50 text-white rounded-lg font-medium transition-colors"
          >
            {saving ? 'Saving...' : 'Save'}
          </button>
        </div>
      </div>
    </div>
  );
}
