import { useState } from 'react';
import { useSongDetail } from '@/hooks/useSongDetail';
import { GenerateModal } from './GenerateModal';
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
  return key || variation.variation_type || '';
}

// Check if variation is a Bass clef chart
function isBassVariation(variation: { variation_type?: string }): boolean {
  return variation.variation_type === 'Bass';
}

interface SongListItemProps {
  song: SongSummary;
  instrument: InstrumentType;
  onSelectVariation: (variation: Variation) => void;
  onOpenPdfUrl: (url: string) => void;
}

export function SongListItem({ song, instrument, onSelectVariation, onOpenPdfUrl }: SongListItemProps) {
  const [showGenerateModal, setShowGenerateModal] = useState(false);
  const isSingleVariation = song.variation_count === 1;

  // Always fetch song details to show variations inline
  const { data: songDetail, isLoading } = useSongDetail(song.title);

  const handleGenerated = (url: string) => {
    setShowGenerateModal(false);
    onOpenPdfUrl(url);
  };

  const filteredVariations = songDetail?.variations.filter((v) => {
    if (instrument !== 'All') {
      const category = getInstrumentCategory(v.variation_type);
      if (category !== instrument) return false;
    }
    return true;
  }) || [];

  // Plus button component
  const PlusButton = () => (
    <button
      onClick={(e) => {
        e.stopPropagation();
        setShowGenerateModal(true);
      }}
      title="Generate in custom key"
      className="p-1.5 rounded-lg bg-white/5 hover:bg-blue-500/20 border border-white/10 hover:border-blue-400 text-gray-400 hover:text-blue-300 transition-all"
    >
      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
      </svg>
    </button>
  );

  // Single variation: whole card opens PDF
  if (isSingleVariation && filteredVariations.length === 1) {
    return (
      <>
        <div className="w-full bg-white/8 backdrop-blur-sm rounded-mcm p-4 border border-white/10 hover:border-blue-400 hover:bg-white/10 transition-all group flex items-center justify-between">
          <button
            onClick={() => onSelectVariation({ ...filteredVariations[0], songTitle: song.title } as any)}
            disabled={isLoading}
            className="flex-1 text-left"
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
          <PlusButton />
        </div>
        {showGenerateModal && (
          <GenerateModal
            songTitle={song.title}
            onClose={() => setShowGenerateModal(false)}
            onGenerated={handleGenerated}
          />
        )}
      </>
    );
  }

  // Multiple variations: show inline buttons
  return (
    <>
      <div className="bg-white/8 backdrop-blur-sm rounded-mcm p-4 border border-white/10 hover:border-white/20 transition-all">
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-base font-medium text-white">
            {song.title}
          </h3>
          <PlusButton />
        </div>

        {isLoading ? (
          <div className="flex items-center gap-2 text-xs text-gray-400">
            <div className="animate-spin rounded-full h-3 w-3 border-b border-blue-400"></div>
            Loading variations...
          </div>
        ) : filteredVariations.length > 0 ? (
          <div className="flex flex-wrap gap-2">
            {filteredVariations.map((variation) => {
              const isBass = isBassVariation(variation);
              return (
                <button
                  key={variation.id}
                  onClick={() => onSelectVariation({ ...variation, songTitle: song.title } as any)}
                  title={isBass ? 'Bass clef chart' : undefined}
                  className={`px-3 py-1.5 text-sm rounded-mcm border transition-all ${
                    isBass
                      ? 'bg-emerald-400/10 hover:bg-emerald-400/20 text-emerald-300 hover:text-emerald-200 border-emerald-400/30 hover:border-emerald-400'
                      : 'bg-blue-400/10 hover:bg-blue-400/20 text-blue-300 hover:text-blue-200 border-blue-400/30 hover:border-blue-400'
                  }`}
                >
                  {formatVariationLabel(variation)}
                </button>
              );
            })}
          </div>
        ) : (
          <div className="text-xs text-gray-500">
            No variations available
          </div>
        )}
      </div>
      {showGenerateModal && (
        <GenerateModal
          songTitle={song.title}
          onClose={() => setShowGenerateModal(false)}
          onGenerated={handleGenerated}
        />
      )}
    </>
  );
}
