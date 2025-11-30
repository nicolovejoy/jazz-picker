import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '@/services/api';
import { GenerateModal } from './GenerateModal';
import type { SongSummary } from '@/types/catalog';
import type { PdfMetadata } from '../App';

// Convert LilyPond key notation to readable format
function formatKey(lilypondKey: string): string {
  if (!lilypondKey) return '';

  // Remove octave markers (commas and apostrophes)
  const cleanKey = lilypondKey.replace(/[,']+$/, '');

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

interface SongListItemProps {
  song: SongSummary;
  onOpenPdfUrl: (url: string, metadata?: PdfMetadata) => void;
}

export function SongListItem({ song, onOpenPdfUrl }: SongListItemProps) {
  const [showGenerateModal, setShowGenerateModal] = useState(false);
  const [isGenerating, setIsGenerating] = useState(false);
  const [generatingKey, setGeneratingKey] = useState<string | null>(null);

  // Fetch cached keys info
  const { data: cachedInfo } = useQuery({
    queryKey: ['cachedKeys', song.title],
    queryFn: () => api.getCachedKeys(song.title),
    staleTime: 60000, // Cache for 1 minute
  });

  const defaultKey = cachedInfo?.default_key || 'c';
  const defaultClef = cachedInfo?.default_clef || 'treble';
  const cachedKeys = cachedInfo?.cached_keys || [];

  // Check if default key is cached
  const isDefaultCached = cachedKeys.some(
    (ck) => ck.key === defaultKey && ck.clef === defaultClef
  );

  // Get other cached keys (not the default)
  const otherCachedKeys = cachedKeys.filter(
    (ck) => !(ck.key === defaultKey && ck.clef === defaultClef)
  );

  // Any cached version exists?
  const hasCachedVersion = cachedKeys.length > 0;

  const handleKeyClick = async (key: string, clef: string, isCached: boolean) => {
    if (isCached) {
      // Fetch the cached PDF directly
      setIsGenerating(true);
      setGeneratingKey(key);
      try {
        const result = await api.generatePDF(song.title, key, clef as 'treble' | 'bass');
        onOpenPdfUrl(result.url, {
          songTitle: song.title,
          key,
          clef,
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
              onClick={() => handleKeyClick(defaultKey, defaultClef, isDefaultCached)}
              disabled={isGenerating}
              className={`px-3 py-1 text-sm rounded-md border transition-all flex items-center gap-1.5 ${
                isDefaultCached
                  ? 'bg-green-500/20 border-green-500/40 text-green-300 hover:bg-green-500/30 hover:border-green-400'
                  : 'bg-white/5 border-white/20 text-gray-400 hover:bg-white/10 hover:border-white/30'
              } ${isGenerating && generatingKey === defaultKey ? 'opacity-50' : ''}`}
            >
              {isGenerating && generatingKey === defaultKey ? (
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
              <span>{formatKey(defaultKey)}</span>
              {defaultClef === 'bass' && (
                <span className="text-xs opacity-60">bass</span>
              )}
            </button>

            {/* Other cached keys */}
            {otherCachedKeys.map((ck) => (
              <button
                key={`${ck.key}-${ck.clef}`}
                onClick={() => handleKeyClick(ck.key, ck.clef, true)}
                disabled={isGenerating}
                className={`px-2 py-1 text-xs rounded-md border transition-all flex items-center gap-1 ${
                  ck.clef === 'bass'
                    ? 'bg-emerald-500/20 border-emerald-500/40 text-emerald-300 hover:bg-emerald-500/30'
                    : 'bg-blue-500/20 border-blue-500/40 text-blue-300 hover:bg-blue-500/30'
                } ${isGenerating && generatingKey === ck.key ? 'opacity-50' : ''}`}
              >
                {isGenerating && generatingKey === ck.key && (
                  <div className="animate-spin rounded-full h-2.5 w-2.5 border-b border-current" />
                )}
                <svg className="w-2.5 h-2.5" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fillRule="evenodd"
                    d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                    clipRule="evenodd"
                  />
                </svg>
                <span>{formatKey(ck.key)}</span>
                {ck.clef === 'bass' && <span className="opacity-60">B</span>}
              </button>
            ))}
          </div>
        </div>

        {/* Plus button area - fixed width on right */}
        <button
          onClick={() => setShowGenerateModal(true)}
          className="w-16 flex items-center justify-center border-l border-white/10 hover:bg-white/5 text-gray-400 hover:text-blue-300 transition-all"
          title="Generate in custom key"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
        </button>
      </div>

      {showGenerateModal && (
        <GenerateModal
          songTitle={song.title}
          defaultKey={defaultKey}
          defaultClef={defaultClef}
          onClose={() => setShowGenerateModal(false)}
          onGenerated={handleGenerated}
        />
      )}
    </>
  );
}
