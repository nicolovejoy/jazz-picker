import { useState } from 'react';
import type { Instrument } from '@/types/catalog';
import { FiSearch, FiX, FiMenu } from 'react-icons/fi';
import { SettingsMenu } from './SettingsMenu';

interface HeaderProps {
  totalSongs: number;
  instrument: Instrument;
  searchQuery: string;
  onInstrumentChange: (instrument: Instrument) => void;
  onSearch: (query: string) => void;
  onEnterPress: () => void;
  onOpenSetlist?: () => void;
  onLogout?: () => void;
  onOpenAbout?: () => void;
}

export function Header({
  totalSongs,
  instrument,
  searchQuery,
  onInstrumentChange,
  onSearch,
  onEnterPress,
  onOpenSetlist,
  onLogout,
  onOpenAbout,
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
              Setlists
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

      {/* Current Instrument Display */}
      <div className="max-w-md mx-auto text-center">
        <span
          className="inline-block px-4 py-2 bg-blue-500/20 border border-blue-400/50 rounded-mcm text-blue-300 text-sm cursor-pointer hover:bg-blue-500/30 transition-colors"
          onClick={() => setIsSettingsOpen(true)}
          title="Click to change instrument in Settings"
        >
          {instrument.label}
          {instrument.transposition !== 'C' && ` (${instrument.transposition})`}
          {instrument.clef === 'bass' && ' • Bass Clef'}
        </span>
      </div>
    </header>

    {/* Settings Menu */}
    <SettingsMenu
      isOpen={isSettingsOpen}
      onClose={() => setIsSettingsOpen(false)}
      currentInstrument={instrument}
      onInstrumentChange={onInstrumentChange}
      onLogout={onLogout}
      onOpenAbout={onOpenAbout}
    />
    </>
  );
}
