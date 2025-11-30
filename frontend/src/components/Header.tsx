import { useState } from 'react';
import type { InstrumentType } from '@/types/catalog';
import { FiSearch, FiX, FiMenu } from 'react-icons/fi';
import { SettingsMenu } from './SettingsMenu';

interface HeaderProps {
  totalSongs: number;
  instrument: InstrumentType;
  searchQuery: string;
  onInstrumentChange: (instrument: InstrumentType) => void;
  onSearch: (query: string) => void;
  onEnterPress: () => void;
  onResetInstrument?: () => void;
  onOpenSetlist?: () => void;
  onLogout?: () => void;
}

export function Header({
  totalSongs,
  instrument,
  searchQuery,
  onInstrumentChange,
  onSearch,
  onEnterPress,
  onResetInstrument,
  onOpenSetlist,
  onLogout,
}: HeaderProps) {
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      onEnterPress();
    }
  };

  return (
    <>
      <header className="bg-white/5 backdrop-blur-lg rounded-mcm p-6 md:p-8 mb-6">
        {/* Top Row - Setlist + Settings */}
        <div className="flex justify-between mb-4">
          {onOpenSetlist ? (
            <button
              onClick={onOpenSetlist}
              className="px-4 py-2 bg-green-500/20 hover:bg-green-500/30 border border-green-500/50 rounded-mcm transition-colors text-green-300 font-medium"
            >
              Gig Setlist
            </button>
          ) : <div />}
          <button
            onClick={() => setIsSettingsOpen(true)}
            className="p-2 bg-white/10 hover:bg-white/20 rounded-mcm transition-colors"
            aria-label="Settings"
          >
            <FiMenu className="text-white text-xl" />
          </button>
        </div>

        <div className="text-center mb-6">
          <h1 className="text-3xl md:text-4xl font-bold text-blue-400 mb-2">
            🎵 Jazz Picker
          </h1>
          <p className="text-gray-400 text-base md:text-lg">Browse Eric's Lead Sheet Collection</p>
          <p className="text-gray-500 text-sm mt-1">{totalSongs} songs</p>
        </div>

      {/* Search Box */}
      <div className="mb-5 max-w-2xl mx-auto">
        <div className="relative">
          <FiSearch className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 text-lg pointer-events-none" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => onSearch(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Search for a song..."
            className="w-full pl-12 pr-12 py-2.5 text-base bg-white/5 backdrop-blur-lg border border-blue-400/50 rounded-mcm text-white placeholder-gray-500 focus:outline-none focus:ring-1 focus:ring-blue-400 focus:border-blue-400 transition-all"
          />
          {searchQuery && (
            <button
              onClick={() => onSearch('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-white transition-colors p-1"
              aria-label="Clear search"
            >
              <FiX className="text-lg" />
            </button>
          )}
        </div>
      </div>

      {/* Instrument Filter */}
      <div className="max-w-md mx-auto">
        <label
          htmlFor="instrument"
          className="block text-xs font-semibold text-gray-400 uppercase tracking-wide mb-1.5"
        >
          Instrument
        </label>
        <select
          id="instrument"
          value={instrument}
          onChange={(e) => onInstrumentChange(e.target.value as InstrumentType)}
          className="w-full px-3 py-2.5 text-sm md:text-base bg-black/30 border border-blue-400/50 rounded-mcm text-white focus:outline-none focus:ring-1 focus:ring-blue-400 focus:border-blue-400 cursor-pointer transition-all"
        >
          <option value="C">C (Piano, Guitar, Vocals)</option>
          <option value="Bb">Bb (Trumpet, Tenor Sax, Clarinet)</option>
          <option value="Eb">Eb (Alto Sax, Bari Sax)</option>
          <option value="Bass">Bass Clef (Bass, Trombone)</option>
          <option value="All">All Charts</option>
        </select>
      </div>
    </header>

    {/* Settings Menu */}
    <SettingsMenu
      isOpen={isSettingsOpen}
      onClose={() => setIsSettingsOpen(false)}
      onResetInstrument={onResetInstrument}
      onLogout={onLogout}
    />
    </>
  );
}
