import { INSTRUMENTS, type Instrument } from '@/types/catalog';

interface WelcomeScreenProps {
  onSelectInstrument: (instrument: Instrument) => void;
}

// Group instruments by transposition for display
const instrumentGroups = [
  {
    label: 'Concert Pitch (C)',
    icon: '🎹',
    instruments: INSTRUMENTS.filter(i => i.transposition === 'C' && i.clef === 'treble'),
  },
  {
    label: 'Bb Instruments',
    icon: '🎺',
    instruments: INSTRUMENTS.filter(i => i.transposition === 'Bb'),
  },
  {
    label: 'Eb Instruments',
    icon: '🎷',
    instruments: INSTRUMENTS.filter(i => i.transposition === 'Eb'),
  },
  {
    label: 'Bass Clef',
    icon: '🎸',
    instruments: INSTRUMENTS.filter(i => i.clef === 'bass'),
  },
];

export function WelcomeScreen({ onSelectInstrument }: WelcomeScreenProps) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 flex items-center justify-center p-6">
      <div className="max-w-lg w-full">
        {/* Header */}
        <div className="text-center mb-10">
          <h1 className="text-4xl md:text-5xl font-bold text-blue-400 mb-3">
            Jazz Picker
          </h1>
          <p className="text-gray-400 text-lg">
            Eric's Lead Sheet Collection
          </p>
        </div>

        {/* Instrument Selection */}
        <div className="space-y-4">
          <p className="text-center text-gray-300 text-sm uppercase tracking-wide mb-4">
            What do you play?
          </p>

          {instrumentGroups.map((group) => (
            <div key={group.label} className="bg-white/5 rounded-lg p-4 border border-white/10">
              <div className="flex items-center gap-2 mb-3">
                <span className="text-xl">{group.icon}</span>
                <h3 className="text-sm font-medium text-gray-400 uppercase tracking-wide">
                  {group.label}
                </h3>
              </div>
              <div className="flex flex-wrap gap-2">
                {group.instruments.map((inst) => (
                  <button
                    key={inst.id}
                    onClick={() => onSelectInstrument(inst)}
                    className="px-4 py-2 bg-white/10 hover:bg-blue-500/30 border border-white/20 hover:border-blue-400 rounded-lg text-white hover:text-blue-200 transition-all text-sm font-medium"
                  >
                    {inst.label}
                  </button>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
