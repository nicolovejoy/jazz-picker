import type { InstrumentType } from '@/types/catalog';

interface WelcomeScreenProps {
  onSelectInstrument: (instrument: InstrumentType) => void;
}

const instruments: { value: InstrumentType; label: string; description: string; icon: string }[] = [
  { value: 'C', label: 'Concert Pitch', description: 'Piano, Guitar, Vocals, Flute', icon: '🎹' },
  { value: 'Bb', label: 'Bb Instruments', description: 'Trumpet, Tenor Sax, Clarinet', icon: '🎺' },
  { value: 'Eb', label: 'Eb Instruments', description: 'Alto Sax, Bari Sax', icon: '🎷' },
  { value: 'Bass', label: 'Bass Clef', description: 'Bass, Trombone, Cello', icon: '🎸' },
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
        <div className="space-y-3">
          <p className="text-center text-gray-300 text-sm uppercase tracking-wide mb-4">
            What do you play?
          </p>

          {instruments.map((inst) => (
            <button
              key={inst.value}
              onClick={() => onSelectInstrument(inst.value)}
              className="w-full bg-white/8 backdrop-blur-sm rounded-mcm p-5 border border-white/10 hover:border-blue-400 hover:bg-white/12 transition-all text-left group"
            >
              <div className="flex items-center gap-4">
                <span className="text-3xl">{inst.icon}</span>
                <div>
                  <h3 className="text-lg font-medium text-white group-hover:text-blue-300 transition-colors">
                    {inst.label}
                  </h3>
                  <p className="text-sm text-gray-400">
                    {inst.description}
                  </p>
                </div>
              </div>
            </button>
          ))}
        </div>

        {/* Browse All option */}
        <div className="mt-6 text-center">
          <button
            onClick={() => onSelectInstrument('All')}
            className="text-gray-500 hover:text-gray-300 text-sm underline underline-offset-2 transition-colors"
          >
            Browse all charts without filtering
          </button>
        </div>
      </div>
    </div>
  );
}
