import { useState } from 'react';
import type { SongSummary, Variation, InstrumentType, SingerRangeType } from '@/types/catalog';
import { FiSearch } from 'react-icons/fi';
import { SongListItem } from './SongListItem';

interface SongListProps {
  songs: SongSummary[];
  instrument: InstrumentType;
  singerRange: SingerRangeType;
  onSelectVariation: (variation: Variation) => void;
  onSearch: (query: string) => void;
}

export function SongList({ songs, instrument, singerRange, onSelectVariation, onSearch }: SongListProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [expandedSong, setExpandedSong] = useState<string | null>(null);

  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    const query = e.target.value;
    setSearchQuery(query);
    onSearch(query);
  };

  const toggleExpand = (songTitle: string) => {
    setExpandedSong(expandedSong === songTitle ? null : songTitle);
  };

  if (songs.length === 0) {
    return (
      <div className="text-center py-20 text-gray-400">
        <p className="text-xl">No songs found</p>
        <p className="text-sm mt-2">Try different filters or search terms</p>
      </div>
    );
  }

  return (
    <div>
      {/* Search Box */}
      <div className="mb-6">
        <div className="relative">
          <FiSearch className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 text-xl" />
          <input
            type="text"
            value={searchQuery}
            onChange={handleSearch}
            placeholder="Search for a song..."
            className="w-full pl-12 pr-4 py-3 text-base md:text-lg bg-white/5 backdrop-blur-lg border-2 border-blue-400/50 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-400 focus:border-transparent transition-all"
          />
        </div>
      </div>

      {/* Songs Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {songs.map((song) => (
          <SongListItem
            key={song.title}
            song={song}
            isExpanded={expandedSong === song.title}
            instrument={instrument}
            singerRange={singerRange}
            onToggle={() => toggleExpand(song.title)}
            onSelectVariation={onSelectVariation}
          />
        ))}
      </div>
    </div>
  );
}
