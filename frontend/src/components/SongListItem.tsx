import { useSongDetail } from '@/hooks/useSongDetail';
import type { SongSummary, Variation, InstrumentType } from '@/types/catalog';
import { getInstrumentCategory } from '@/types/catalog';

// Convert LilyPond key notation to readable format
// e.g., "bf," -> "B♭", "df" -> "D♭", "fs" -> "F♯"
function formatKey(lilypondKey: string): string {
  if (!lilypondKey) return '';

  // Remove octave markers (commas and apostrophes)
  const cleanKey = lilypondKey.replace(/[,']+$/, '');

  // Map LilyPond note names to readable format
  const noteMap: Record<string, string> = {
    'c': 'C', 'cs': 'C♯', 'cf': 'C♭',
    'd': 'D', 'ds': 'D♯', 'df': 'D♭',
    'e': 'E', 'es': 'E♯', 'ef': 'E♭',
    'f': 'F', 'fs': 'F♯', 'ff': 'F♭',
    'g': 'G', 'gs': 'G♯', 'gf': 'G♭',
    'a': 'A', 'as': 'A♯', 'af': 'A♭',
    'b': 'B', 'bs': 'B♯', 'bf': 'B♭',
  };

  return noteMap[cleanKey] || cleanKey.toUpperCase();
}

// Format variation for button display
function formatVariationLabel(variation: { key?: string; variation_type?: string }): string {
  const key = formatKey(variation.key || '');
  const type = variation.variation_type || '';

  // Add suffix for Bass variations
  if (type === 'Bass') {
    return key ? `${key} (Bass)` : 'Bass';
  }

  return key || type;
}

interface SongListItemProps {
  song: SongSummary;
  instrument: InstrumentType;
  onSelectVariation: (variation: Variation) => void;
}

export function SongListItem({ song, instrument, onSelectVariation }: SongListItemProps) {
  const isSingleVariation = song.variation_count === 1;

  // Always fetch song details to show variations inline
  const { data: songDetail, isLoading } = useSongDetail(song.title);

  const filteredVariations = songDetail?.variations.filter((v) => {
    if (instrument !== 'All') {
      const category = getInstrumentCategory(v.variation_type);
      if (category !== instrument) return false;
    }
    return true;
  }) || [];

  // Single variation: whole card opens PDF
  if (isSingleVariation && filteredVariations.length === 1) {
    return (
      <button
        onClick={() => onSelectVariation(filteredVariations[0] as any)}
        disabled={isLoading}
        className="w-full bg-white/8 backdrop-blur-sm rounded-mcm p-4 border border-white/10 hover:border-blue-400 hover:bg-white/10 transition-all text-left group"
      >
        <h3 className="text-base font-medium text-white group-hover:text-blue-300 transition-colors">
          {song.title}
        </h3>
        {isLoading && (
          <div className="flex items-center gap-2 mt-2 text-xs text-gray-400">
            <div className="animate-spin rounded-full h-3 w-3 border-b border-blue-400"></div>
            Loading...
          </div>
        )}
      </button>
    );
  }

  // Multiple variations: show inline buttons
  return (
    <div className="bg-white/8 backdrop-blur-sm rounded-mcm p-4 border border-white/10 hover:border-white/20 transition-all">
      <h3 className="text-base font-medium text-white mb-3">
        {song.title}
      </h3>

      {isLoading ? (
        <div className="flex items-center gap-2 text-xs text-gray-400">
          <div className="animate-spin rounded-full h-3 w-3 border-b border-blue-400"></div>
          Loading variations...
        </div>
      ) : filteredVariations.length > 0 ? (
        <div className="flex flex-wrap gap-2">
          {filteredVariations.map((variation) => (
            <button
              key={variation.id}
              onClick={() => onSelectVariation(variation as any)}
              className="px-3 py-1.5 text-sm bg-blue-400/10 hover:bg-blue-400/20 text-blue-300 hover:text-blue-200 rounded-mcm border border-blue-400/30 hover:border-blue-400 transition-all"
            >
              {formatVariationLabel(variation)}
            </button>
          ))}
        </div>
      ) : (
        <div className="text-xs text-gray-500">
          No variations available
        </div>
      )}
    </div>
  );
}
