import { useSongDetail } from '@/hooks/useSongDetail';
import type { SongSummary, Variation, InstrumentType, SingerRangeType } from '@/types/catalog';
import { getInstrumentCategory, getSingerRangeCategory } from '@/types/catalog';
import { FiChevronDown, FiChevronUp } from 'react-icons/fi';

interface SongListItemProps {
  song: SongSummary;
  isExpanded: boolean;
  instrument: InstrumentType;
  singerRange: SingerRangeType;
  onToggle: () => void;
  onSelectVariation: (variation: Variation) => void;
}

export function SongListItem({ song, isExpanded, instrument, singerRange, onToggle, onSelectVariation }: SongListItemProps) {
  // Fetch details only when expanded
  const { data: songDetail, isLoading } = useSongDetail(isExpanded ? song.title : null);

  // Extract unique keys for badge display from summary
  const badges = [...song.available_instruments];

  // Filter variations based on selected filters
  const filteredVariations = songDetail?.variations.filter((v) => {
    // Filter by instrument
    if (instrument !== 'All') {
      const category = getInstrumentCategory(v.variation_type);
      if (category !== instrument) return false;
    }

    // Filter by singer range
    if (singerRange !== 'All') {
      const category = getSingerRangeCategory(v.variation_type);
      if (category !== singerRange) return false;
    }

    return true;
  }) || [];

  return (
    <div className="bg-white/8 backdrop-blur-sm rounded-xl p-4 border border-white/10 hover:border-blue-400/50 transition-all">
      {/* Song Title - Click to expand */}
      <button
        onClick={onToggle}
        className="w-full text-left"
      >
        <div className="flex items-start justify-between gap-2">
          <h3 className="text-lg font-semibold text-white flex-1">
            {song.title}
          </h3>
          {isExpanded ? (
            <FiChevronUp className="text-blue-400 text-xl flex-shrink-0 mt-1" />
          ) : (
            <FiChevronDown className="text-gray-400 text-xl flex-shrink-0 mt-1" />
          )}
        </div>

        {/* Badges (Instruments) */}
        {!isExpanded && (
          <div className="flex flex-wrap gap-2 mt-3">
            {badges.map((badge) => (
              <span
                key={badge}
                className="px-3 py-1 text-sm rounded-full bg-blue-400/20 text-blue-300 border border-blue-400/30"
              >
                {badge}
              </span>
            ))}
            <span className="px-3 py-1 text-sm rounded-full bg-gray-700/50 text-gray-300 border border-gray-600/30">
              {song.variation_count} vars
            </span>
          </div>
        )}
      </button>

      {/* Expanded Variations List */}
      {isExpanded && (
        <div className="mt-4 pt-4 border-t border-white/10 space-y-2">
          {isLoading ? (
            <div className="text-center py-4 text-gray-400">
              <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-400 mx-auto mb-2"></div>
              Loading details...
            </div>
          ) : filteredVariations.length > 0 ? (
            filteredVariations.map((variation) => {
              // Extract key name for display
               const keyMatch = variation.key || variation.display_name.split(' - ')[1] || 'Unknown';

              return (
                <button
                  key={variation.id}
                  onClick={() => onSelectVariation(variation as any)}
                  className="w-full p-3 bg-black/20 hover:bg-blue-400/20 rounded-lg border border-transparent hover:border-blue-400 transition-all text-left"
                >
                  <div className="font-semibold text-blue-400">{keyMatch}</div>
                  {variation.instrument && (
                    <div className="text-sm text-gray-400 mt-1">
                      {variation.instrument}
                    </div>
                  )}
                </button>
              );
            })
          ) : (
            <div className="text-center py-2 text-gray-500 text-sm">
              No variations match current filters.
            </div>
          )}
        </div>
      )}
    </div>
  );
}
