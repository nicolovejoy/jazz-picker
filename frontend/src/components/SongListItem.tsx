import { useState, useEffect } from 'react';
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
  const [shouldFetch, setShouldFetch] = useState(false);
  const isSingleVariation = song.variation_count === 1;

  const { data: songDetail, isLoading } = useSongDetail(isExpanded || shouldFetch ? song.title : null);

  useEffect(() => {
    if (shouldFetch && songDetail && !isLoading && isSingleVariation) {
      const variations = songDetail.variations;
      if (variations.length > 0) {
        onSelectVariation(variations[0] as any);
        setShouldFetch(false);
      }
    }
  }, [shouldFetch, songDetail, isLoading, isSingleVariation, onSelectVariation]);

  const handleClick = () => {
    if (isSingleVariation) {
      setShouldFetch(true);
    } else {
      onToggle();
    }
  };

  const badges = [...song.available_instruments];

  const filteredVariations = songDetail?.variations.filter((v) => {
    if (instrument !== 'All') {
      const category = getInstrumentCategory(v.variation_type);
      if (category !== instrument) return false;
    }

    if (singerRange !== 'All') {
      const category = getSingerRangeCategory(v.variation_type);
      if (category !== singerRange) return false;
    }

    return true;
  }) || [];

  return (
    <div className="bg-white/8 backdrop-blur-sm rounded-mcm p-5 border border-white/10 hover:border-blue-400/50 transition-all min-h-[70px]">
      <button
        onClick={handleClick}
        className="w-full text-left"
        disabled={shouldFetch && isLoading}
      >
        <div className="flex items-center justify-between gap-3">
          <h3 className="text-lg font-semibold text-white flex-1">
            {song.title}
          </h3>
          <div className="flex items-center gap-2 flex-shrink-0">
            {!isExpanded && (
              <>
                <div className="hidden sm:flex gap-1.5">
                  {badges.slice(0, 3).map((badge) => (
                    <span
                      key={badge}
                      className="px-2.5 py-0.5 text-xs rounded-mcm bg-blue-400/15 text-blue-300 border border-blue-400/25"
                    >
                      {badge}
                    </span>
                  ))}
                </div>
                <span className="px-2.5 py-0.5 text-xs rounded-mcm bg-gray-700/40 text-gray-300 border border-gray-600/25">
                  {song.variation_count} {song.variation_count === 1 ? 'var' : 'vars'}
                </span>
              </>
            )}
            {shouldFetch && isLoading ? (
              <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-400"></div>
            ) : !isSingleVariation && (
              isExpanded ? (
                <FiChevronUp className="text-blue-400 text-xl" />
              ) : (
                <FiChevronDown className="text-gray-400 text-xl" />
              )
            )}
          </div>
        </div>

        {!isExpanded && isSingleVariation && (
          <p className="text-xs text-gray-500 mt-1.5">Tap to view PDF</p>
        )}
      </button>

      {isExpanded && (
        <div className="mt-4 pt-4 border-t border-white/10">
          {isLoading ? (
            <div className="text-center py-6 text-gray-400">
              <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-400 mx-auto mb-2"></div>
              Loading variations...
            </div>
          ) : filteredVariations.length > 0 ? (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2.5">
              {filteredVariations.map((variation) => {
                const keyMatch = variation.key || variation.display_name.split(' - ')[1] || 'Unknown';

                return (
                  <button
                    key={variation.id}
                    onClick={() => onSelectVariation(variation as any)}
                    className="p-3 bg-black/20 hover:bg-blue-400/20 rounded-mcm border border-white/10 hover:border-blue-400 transition-all text-center group"
                  >
                    <div className="font-semibold text-blue-400 group-hover:text-blue-300 text-sm">
                      {keyMatch}
                    </div>
                    {variation.instrument && (
                      <div className="text-xs text-gray-400 mt-1">
                        {variation.instrument}
                      </div>
                    )}
                  </button>
                );
              })}
            </div>
          ) : (
            <div className="text-center py-4 text-gray-500 text-sm">
              No variations match current filters.
            </div>
          )}
        </div>
      )}
    </div>
  );
}
