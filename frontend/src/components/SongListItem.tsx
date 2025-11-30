import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '@/services/api';
import { GenerateModal } from './GenerateModal';
import { formatKey, concertToWritten, type SongSummary, type Instrument } from '@/types/catalog';
import type { PdfMetadata } from '../App';

import { FiPlus } from 'react-icons/fi';

interface SongListItemProps {
  song: SongSummary;
  instrument: Instrument;
  onOpenPdfUrl: (url: string, metadata?: PdfMetadata) => void;
  onAddToSetlist: (song: SongSummary) => void;
}

export function SongListItem({ song, instrument, onOpenPdfUrl, onAddToSetlist }: SongListItemProps) {
  const [showGenerateModal, setShowGenerateModal] = useState(false);
  const [isGenerating, setIsGenerating] = useState(false);
  const [generatingKey, setGeneratingKey] = useState<string | null>(null);

  // Fetch cached concert keys for this song + user's transposition
  const { data: cachedInfo } = useQuery({
    queryKey: ['cachedKeys', song.title, instrument.transposition, instrument.clef],
    queryFn: () => api.getCachedKeys(song.title, instrument.transposition, instrument.clef),
    staleTime: 60000, // Cache for 1 minute
  });

  const defaultConcertKey = cachedInfo?.default_key || song.default_key || 'c';
  const cachedConcertKeys = cachedInfo?.cached_concert_keys || [];

  // Check if default key is cached
  const isDefaultCached = cachedConcertKeys.includes(defaultConcertKey);

  // Get other cached keys (not the default)
  const otherCachedKeys = cachedConcertKeys.filter((k) => k !== defaultConcertKey);

  // Any cached version exists?
  const hasCachedVersion = cachedConcertKeys.length > 0;

  // Format key for display - show written key for transposing instruments
  const displayKey = (concertKey: string) => {
    if (instrument.transposition === 'C') {
      return formatKey(concertKey);
    }
    const writtenKey = concertToWritten(concertKey, instrument.transposition);
    return formatKey(writtenKey);
  };

  const handleKeyClick = async (concertKey: string, isCached: boolean) => {
    if (isCached) {
      // Fetch the cached PDF directly
      setIsGenerating(true);
      setGeneratingKey(concertKey);
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
        });
      } catch (err) {
        console.error('Failed to fetch PDF:', err);
      } finally {
        setIsGenerating(false);
        setGeneratingKey(null);
      }
    } else {
      // Open generate modal with this key pre-selected
      setShowGenerateModal(true);
    }
  };

  const handleGenerated = (url: string) => {
    setShowGenerateModal(false);
    onOpenPdfUrl(url);
  };

  return (
    <>
      <div
        className={`w-full bg-white/8 backdrop-blur-sm rounded-lg border transition-all flex items-stretch ${
          hasCachedVersion
            ? 'border-green-500/30 hover:border-green-400/50'
            : 'border-white/10 hover:border-white/20'
        }`}
      >
        {/* Main content area - 80% */}
        <div className="flex-1 p-4 min-w-0">
          <h3 className="text-base font-medium text-white truncate mb-2">
            {song.title}
          </h3>

          <div className="flex flex-wrap gap-2 items-center">
            {/* Default key button */}
            <button
              onClick={() => handleKeyClick(defaultConcertKey, isDefaultCached)}
              disabled={isGenerating}
              className={`px-3 py-1 text-sm rounded-md border transition-all flex items-center gap-1.5 ${
                isDefaultCached
                  ? 'bg-green-500/20 border-green-500/40 text-green-300 hover:bg-green-500/30 hover:border-green-400'
                  : 'bg-white/5 border-white/20 text-gray-400 hover:bg-white/10 hover:border-white/30'
              } ${isGenerating && generatingKey === defaultConcertKey ? 'opacity-50' : ''}`}
            >
              {isGenerating && generatingKey === defaultConcertKey ? (
                <div className="animate-spin rounded-full h-3 w-3 border-b border-current" />
              ) : isDefaultCached ? (
                <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fillRule="evenodd"
                    d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                    clipRule="evenodd"
                  />
                </svg>
              ) : null}
              <span>{displayKey(defaultConcertKey)}</span>
            </button>

            {/* Other cached keys */}
            {otherCachedKeys.map((concertKey) => (
              <button
                key={concertKey}
                onClick={() => handleKeyClick(concertKey, true)}
                disabled={isGenerating}
                className={`px-2 py-1 text-xs rounded-md border transition-all flex items-center gap-1 bg-blue-500/20 border-blue-500/40 text-blue-300 hover:bg-blue-500/30 ${
                  isGenerating && generatingKey === concertKey ? 'opacity-50' : ''
                }`}
              >
                {isGenerating && generatingKey === concertKey && (
                  <div className="animate-spin rounded-full h-2.5 w-2.5 border-b border-current" />
                )}
                <svg className="w-2.5 h-2.5" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fillRule="evenodd"
                    d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                    clipRule="evenodd"
                  />
                </svg>
                <span>{displayKey(concertKey)}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Action Buttons Area */}
        <div className="flex flex-col border-l border-white/10">
          {/* Add to Setlist Button */}
          <button
            onClick={() => onAddToSetlist(song)}
            className="flex-1 w-12 flex items-center justify-center hover:bg-white/5 text-gray-400 hover:text-blue-300 transition-all border-b border-white/10"
            title="Add to Setlist"
          >
            <FiPlus className="text-lg" />
          </button>

          {/* Generate Custom Key Button */}
          <button
            onClick={() => setShowGenerateModal(true)}
            className="flex-1 w-12 flex items-center justify-center hover:bg-white/5 text-gray-400 hover:text-blue-300 transition-all"
            title="Generate in custom key"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
          </button>
        </div>
      </div>

      {showGenerateModal && (
        <GenerateModal
          songTitle={song.title}
          defaultConcertKey={defaultConcertKey}
          instrument={instrument}
          onClose={() => setShowGenerateModal(false)}
          onGenerated={handleGenerated}
        />
      )}
    </>
  );
}
