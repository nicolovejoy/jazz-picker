import { useState, useMemo } from 'react';
import type { Song, Variation, InstrumentType, SingerRangeType } from '@/types/catalog';
import { FiSearch, FiChevronDown, FiChevronUp } from 'react-icons/fi';

interface SongListProps {
  songs: Song[];
  instrument: InstrumentType;
  singerRange: SingerRangeType;
  onSelectVariation: (variation: Variation) => void;
}

export function SongList({ songs, instrument, singerRange, onSelectVariation }: SongListProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [expandedSong, setExpandedSong] = useState<string | null>(null);

  // Filter songs based on instrument and singer range
  const filteredSongs = useMemo(() => {
    return songs
      .map((song) => {
        // Filter variations based on selected filters
        let filteredVariations = song.variations;

        // Filter by instrument
        if (instrument !== 'All') {
          filteredVariations = filteredVariations.filter((v: Variation) => {
            if (instrument === 'C') {
              return v.variation_type === 'Standard (Concert)' ||
                     v.variation_type === 'Alto Voice' ||
                     v.variation_type === 'Baritone Voice';
            }
            if (instrument === 'Bb') {
              return v.variation_type === 'Bb Instrument';
            }
            if (instrument === 'Eb') {
              return v.variation_type === 'Eb Instrument';
            }
            if (instrument === 'Bass') {
              return v.variation_type === 'Bass';
            }
            return true;
          });
        }

        // Filter by singer range
        if (singerRange !== 'All') {
          filteredVariations = filteredVariations.filter((v: Variation) => {
            if (singerRange === 'Alto/Mezzo/Soprano') {
              return v.variation_type === 'Alto Voice';
            }
            if (singerRange === 'Baritone/Tenor/Bass') {
              return v.variation_type === 'Baritone Voice';
            }
            if (singerRange === 'Standard') {
              return v.variation_type === 'Standard (Concert)';
            }
            return true;
          });
        }

        if (filteredVariations.length === 0) return null;

        return { ...song, variations: filteredVariations };
      })
      .filter((song): song is Song => song !== null);
  }, [songs, instrument, singerRange]);

  // Filter by search query
  const searchedSongs = useMemo(() => {
    if (!searchQuery) return filteredSongs;
    const query = searchQuery.toLowerCase();
    return filteredSongs.filter((song) =>
      song.title.toLowerCase().includes(query)
    );
  }, [filteredSongs, searchQuery]);

  const toggleExpand = (songTitle: string) => {
    setExpandedSong(expandedSong === songTitle ? null : songTitle);
  };

  if (searchedSongs.length === 0) {
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
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search for a song..."
            className="w-full pl-12 pr-4 py-3 text-base md:text-lg bg-white/5 backdrop-blur-lg border-2 border-blue-400/50 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-400 focus:border-transparent transition-all"
          />
        </div>
      </div>

      {/* Songs Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {searchedSongs.map((song) => {
          const isExpanded = expandedSong === song.title;

          // Extract unique keys for badge display
          const uniqueKeys = Array.from(
            new Set(
              song.variations.map((v: Variation) => {
                const match = v.key_and_variation.match(/^([A-G][b#]?m?)/);
                return match ? match[1] : v.key_and_variation.split(' ')[0];
              })
            )
          );

          return (
            <div
              key={song.title}
              className="bg-white/8 backdrop-blur-sm rounded-xl p-4 border border-white/10 hover:border-blue-400/50 transition-all"
            >
              {/* Song Title - Click to expand */}
              <button
                onClick={() => toggleExpand(song.title)}
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

                {/* Key Badges */}
                {!isExpanded && (
                  <div className="flex flex-wrap gap-2 mt-3">
                    {uniqueKeys.map((key) => (
                      <span
                        key={key}
                        className="px-3 py-1 text-sm rounded-full bg-blue-400/20 text-blue-300 border border-blue-400/30"
                      >
                        {key}
                      </span>
                    ))}
                  </div>
                )}
              </button>

              {/* Expanded Variations List */}
              {isExpanded && (
                <div className="mt-4 pt-4 border-t border-white/10 space-y-2">
                  {song.variations.map((variation: Variation) => {
                    const keyMatch = variation.key_and_variation.match(/^([A-G][b#]?m?)/);
                    const keyName = keyMatch ? keyMatch[1] : variation.key_and_variation.split(' ')[0];

                    return (
                      <button
                        key={variation.filename}
                        onClick={() => onSelectVariation(variation)}
                        className="w-full p-3 bg-black/20 hover:bg-blue-400/20 rounded-lg border border-transparent hover:border-blue-400 transition-all text-left"
                      >
                        <div className="font-semibold text-blue-400">{keyName}</div>
                        {variation.instrument && (
                          <div className="text-sm text-gray-400 mt-1">
                            {variation.instrument}
                          </div>
                        )}
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
