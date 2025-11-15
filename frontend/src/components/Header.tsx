import type { InstrumentType, SingerRangeType } from '@/types/catalog';

interface HeaderProps {
  totalSongs: number;
  instrument: InstrumentType;
  singerRange: SingerRangeType;
  onInstrumentChange: (instrument: InstrumentType) => void;
  onSingerRangeChange: (range: SingerRangeType) => void;
}

const singerRangeColors: Record<SingerRangeType, string> = {
  'Alto/Mezzo/Soprano': 'border-alto bg-alto/10',
  'Baritone/Tenor/Bass': 'border-baritone bg-baritone/10',
  'Standard': 'border-standard bg-standard/10',
  'All': 'border-all-keys bg-all-keys/10',
};

export function Header({
  totalSongs,
  instrument,
  singerRange,
  onInstrumentChange,
  onSingerRangeChange,
}: HeaderProps) {
  return (
    <header className="bg-white/5 backdrop-blur-lg rounded-2xl p-6 md:p-8 mb-6">
      <div className="text-center mb-6">
        <h1 className="text-4xl md:text-5xl font-bold text-blue-400 mb-2">
          🎵 Jazz Picker
        </h1>
        <p className="text-gray-400 text-lg">Browse Eric's Lead Sheet Collection</p>
        <p className="text-gray-500 text-sm mt-2">{totalSongs} songs</p>
      </div>

      <div className="flex flex-col md:flex-row gap-4 md:gap-6 max-w-2xl mx-auto">
        {/* Instrument Filter */}
        <div className="flex-1">
          <label
            htmlFor="instrument"
            className="block text-sm font-semibold text-gray-300 mb-2"
          >
            Instrument
          </label>
          <select
            id="instrument"
            value={instrument}
            onChange={(e) => onInstrumentChange(e.target.value as InstrumentType)}
            className="w-full px-4 py-3 text-base md:text-lg bg-black/30 border-2 border-blue-400 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-400 focus:border-transparent cursor-pointer transition-all"
          >
            <option value="C">C (Piano, Guitar, Vocals)</option>
            <option value="Bb">Bb (Trumpet, Tenor Sax, Clarinet)</option>
            <option value="Eb">Eb (Alto Sax, Bari Sax)</option>
            <option value="Bass">Bass Clef (Bass, Trombone)</option>
            <option value="All">All Charts</option>
          </select>
        </div>

        {/* Singer Range Filter */}
        <div className="flex-1">
          <label
            htmlFor="singerRange"
            className="block text-sm font-semibold text-gray-300 mb-2"
          >
            Singer Range Preference
          </label>
          <select
            id="singerRange"
            value={singerRange}
            onChange={(e) => onSingerRangeChange(e.target.value as SingerRangeType)}
            className={`w-full px-4 py-3 text-base md:text-lg bg-black/30 border-2 rounded-lg text-white focus:outline-none focus:ring-2 focus:border-transparent cursor-pointer transition-all ${singerRangeColors[singerRange]}`}
          >
            <option value="Alto/Mezzo/Soprano">🟣 Alto/Mezzo/Soprano</option>
            <option value="Baritone/Tenor/Bass">🟢 Baritone/Tenor/Bass</option>
            <option value="Standard">⚪ Standard Keys</option>
            <option value="All">🟦 All Keys</option>
          </select>
        </div>
      </div>
    </header>
  );
}
