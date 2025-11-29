import type { SongSummary, Variation, InstrumentType } from '@/types/catalog';
import { SongListItem } from './SongListItem';

interface SongListProps {
  songs: SongSummary[];
  instrument: InstrumentType;
  searchQuery: string;
  onSelectVariation: (variation: Variation) => void;
  onOpenPdfUrl: (url: string) => void;
}

export function SongList({ songs, instrument, searchQuery, onSelectVariation, onOpenPdfUrl }: SongListProps) {

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

  // Deduplicate songs by title (just in case)
  const uniqueSongs = Array.from(
    new Map(songs.map(song => [song.title, song])).values()
  );

  return (
    <div>

      {/* Songs Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {uniqueSongs.map((song, index) => (
          <SongListItem
            key={`${song.title}-${index}`}
            song={song}
            instrument={instrument}
            onSelectVariation={onSelectVariation}
            onOpenPdfUrl={onOpenPdfUrl}
          />
        ))}
      </div>
    </div>
  );
}
