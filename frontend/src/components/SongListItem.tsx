import { useCallback } from 'react';
import { api } from '@/services/api';
import { formatKey, concertToWritten, type SongSummary, type Instrument } from '@/types/catalog';
import type { PdfMetadata } from '../App';
import { useUserProfile } from '@/contexts/UserProfileContext';

interface SongListItemProps {
  song: SongSummary;
  instrument: Instrument;
  onOpenPdfUrl: (url: string, metadata?: PdfMetadata) => void;
}

// Format key for display based on instrument transposition
function displayKeyWithMode(concertKey: string, instrument: Instrument): string {
  const isMinor = concertKey.endsWith('m');
  const baseKey = isMinor ? concertKey.slice(0, -1) : concertKey;

  let displayBase: string;
  if (instrument.transposition === 'C') {
    displayBase = formatKey(baseKey);
  } else {
    displayBase = formatKey(concertToWritten(baseKey, instrument.transposition));
  }

  return isMinor ? `${displayBase} Minor` : `${displayBase} Major`;
}

export function SongListItem({ song, instrument, onOpenPdfUrl }: SongListItemProps) {
  const { getPreferredKey, setPreferredKey } = useUserProfile();

  const standardKey = song.default_key || 'c';
  const preferredKey = getPreferredKey(song.title, standardKey);
  const hasPreference = preferredKey !== standardKey;

  const openPdf = useCallback(async (concertKey: string) => {
    try {
      const result = await api.generatePDF(
        song.title,
        concertKey,
        instrument.transposition,
        instrument.clef,
        instrument.label
      );
      onOpenPdfUrl(result.url, {
        songTitle: song.title,
        key: concertKey,
        clef: instrument.clef,
        cached: result.cached,
        generationTimeMs: result.generation_time_ms,
        crop: result.crop,
      });
      // Update preferred key after successful load
      setPreferredKey(song.title, concertKey, standardKey).catch(console.error);
    } catch (err) {
      console.error('Failed to fetch PDF:', err);
    }
  }, [song.title, instrument, onOpenPdfUrl, setPreferredKey, standardKey]);

  const handleCardClick = () => {
    openPdf(preferredKey);
  };

  const handleStandardKeyClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    openPdf(standardKey);
  };

  return (
    <div
      onClick={handleCardClick}
      className="w-full px-4 py-3 rounded border cursor-pointer transition-all bg-white/5 border-white/10 hover:border-white/20"
    >
      <div className="flex items-center gap-3">
        {/* Title */}
        <h3 className="text-base font-medium truncate flex-1 min-w-0 text-white">
          {song.title}
        </h3>

        {/* Key badges */}
        <div className="flex items-center gap-1.5 shrink-0 text-sm">
          <button
            onClick={handleStandardKeyClick}
            className="text-gray-400 hover:text-white transition-colors"
          >
            {displayKeyWithMode(standardKey, instrument)}
          </button>
          {hasPreference && (
            <span className="text-orange-300">
              ({displayKeyWithMode(preferredKey, instrument)})
            </span>
          )}
        </div>
      </div>
    </div>
  );
}
