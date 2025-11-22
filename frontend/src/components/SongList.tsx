import { useState } from 'react';
import type { SongSummary, Variation, InstrumentType, SingerRangeType } from '@/types/catalog';
import { SongListItem } from './SongListItem';

interface SongListProps {
  songs: SongSummary[];
  instrument: InstrumentType;
  singerRange: SingerRangeType;
  searchQuery: string;
  onSelectVariation: (variation: Variation) => void;
}

export function SongList({ songs, instrument, singerRange, searchQuery, onSelectVariation }: SongListProps) {
  const [expandedSong, setExpandedSong] = useState<string | null>(null);

  const toggleExpand = (songTitle: string) => {
    setExpandedSong(expandedSong === songTitle ? null : songTitle);
  };

  if (songs.length === 0) {
    return (
      <div className="text-center py-20 text-gray-400">
        <p className="text-xl">No songs found</p>
        {searchQuery && (
          <p className="text-sm mt-2">
            No results for <span className="text-blue-400 font-semibold">"{searchQuery}"</span>
          </p>
        )}
        <p className="text-sm mt-2">Try different filters or search terms</p>
      </div>
    );
  }

  return (
    <div>

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
