import { useState, useRef, useCallback } from 'react';
import { useQuery } from '@tanstack/react-query';
import { api } from '@/services/api';
import { GenerateModal } from './GenerateModal';
import { formatKey, concertToWritten, type SongSummary, type Instrument } from '@/types/catalog';
import type { PdfMetadata } from '../App';
import { FiPlus, FiMusic } from 'react-icons/fi';

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
  const [loadingMessage, setLoadingMessage] = useState<string>('');
  const [showActions, setShowActions] = useState(false);

  const longPressTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const didLongPress = useRef(false);
  const isTouch = useRef(false);

  const { data: cachedInfo } = useQuery({
    queryKey: ['cachedKeys', song.title, instrument.transposition, instrument.clef],
    queryFn: () => api.getCachedKeys(song.title, instrument.transposition, instrument.clef),
    staleTime: 60000,
  });

  const defaultConcertKey = cachedInfo?.default_key || song.default_key || 'c';
  const cachedConcertKeys = cachedInfo?.cached_concert_keys || [];
  const isDefaultCached = cachedConcertKeys.includes(defaultConcertKey);
  const otherCachedKeys = cachedConcertKeys.filter((k) => k !== defaultConcertKey);
  const hasCachedVersion = cachedConcertKeys.length > 0;

  const displayKey = (concertKey: string) => {
    if (instrument.transposition === 'C') {
      return formatKey(concertKey);
    }
    return formatKey(concertToWritten(concertKey, instrument.transposition));
  };

  const openPdf = useCallback(async (concertKey: string) => {
    const isCached = cachedConcertKeys.includes(concertKey);
    setIsGenerating(true);
    setGeneratingKey(concertKey);
    setLoadingMessage(isCached ? 'Loading from cache...' : 'Generating from LilyPond...');
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
    } catch (err) {
      console.error('Failed to fetch PDF:', err);
      console.error('Error details:', {
        name: (err as Error)?.name,
        message: (err as Error)?.message,
        stack: (err as Error)?.stack,
      });
    } finally {
      setIsGenerating(false);
      setGeneratingKey(null);
      setLoadingMessage('');
    }
  }, [song.title, instrument, onOpenPdfUrl, cachedConcertKeys]);

  const handleCardClick = () => {
    // If this was a long-press, don't open PDF
    if (didLongPress.current) {
      didLongPress.current = false;
      return;
    }
    // On touch, if actions are showing, dismiss them instead of opening PDF
    if (isTouch.current && showActions) {
      setShowActions(false);
      return;
    }
    openPdf(defaultConcertKey);
  };

  const handleKeyClick = (e: React.MouseEvent, concertKey: string) => {
    e.stopPropagation();
    openPdf(concertKey);
  };

  // Long press for touch devices
  const handleTouchStart = () => {
    isTouch.current = true;
    didLongPress.current = false;
    longPressTimer.current = setTimeout(() => {
      didLongPress.current = true;
      setShowActions(true);
    }, 400);
  };

  const handleTouchEnd = () => {
    if (longPressTimer.current) {
      clearTimeout(longPressTimer.current);
      longPressTimer.current = null;
    }
  };

  // Click outside to dismiss actions
  const handleActionBlur = () => {
    setTimeout(() => setShowActions(false), 150);
  };

  return (
    <>
      <div
        onClick={handleCardClick}
        onMouseEnter={() => setShowActions(true)}
        onMouseLeave={() => setShowActions(false)}
        onTouchStart={handleTouchStart}
        onTouchEnd={handleTouchEnd}
        onTouchCancel={handleTouchEnd}
        className={`relative w-full px-4 py-3 rounded border cursor-pointer transition-all ${
          hasCachedVersion
            ? 'bg-white/5 border-green-500/20 hover:border-green-400/40'
            : 'bg-white/5 border-white/10 hover:border-white/20'
        } ${isGenerating ? 'opacity-70' : ''}`}
      >
        <div className="flex items-center gap-3">
          {/* Loading Spinner */}
          {isGenerating && (
            <div className="w-5 h-5 border-2 border-blue-400/30 border-t-blue-400 rounded-full animate-spin shrink-0" />
          )}

          {/* Title */}
          <h3 className={`text-base font-medium truncate flex-1 min-w-0 ${isGenerating ? 'text-blue-300' : 'text-white'}`}>
            {isGenerating ? loadingMessage : song.title}
          </h3>

          {/* Key Pills - inline with title */}
          <div className={`flex items-center gap-1 shrink-0 ${isGenerating ? 'opacity-40' : ''}`}>
            <button
              onClick={(e) => handleKeyClick(e, defaultConcertKey)}
              disabled={isGenerating}
              className={`px-2 py-0.5 text-sm rounded transition-all ${
                isDefaultCached
                  ? 'bg-green-500/20 text-green-300'
                  : 'bg-white/5 text-gray-500'
              }`}
            >
              {generatingKey === defaultConcertKey ? '...' : displayKey(defaultConcertKey)}
            </button>

            {otherCachedKeys.slice(0, 2).map((concertKey) => (
              <button
                key={concertKey}
                onClick={(e) => handleKeyClick(e, concertKey)}
                disabled={isGenerating}
                className="px-2 py-0.5 text-sm rounded bg-blue-500/15 text-blue-300 transition-all"
              >
                {generatingKey === concertKey ? '...' : displayKey(concertKey)}
              </button>
            ))}
            {otherCachedKeys.length > 2 && (
              <span className="text-xs text-gray-600">+{otherCachedKeys.length - 2}</span>
            )}
          </div>
        </div>

        {/* Hover/Long-press Actions */}
        <div
          onBlur={handleActionBlur}
          className={`absolute right-3 top-1/2 -translate-y-1/2 flex items-center gap-1.5 transition-all duration-150 ${
            showActions
              ? 'opacity-100 translate-x-0'
              : 'opacity-0 translate-x-2 pointer-events-none'
          }`}
        >
          <button
            onClick={(e) => {
              e.stopPropagation();
              setShowActions(false);
              onAddToSetlist(song);
            }}
            className="flex items-center gap-1.5 px-2 py-1.5 rounded bg-gray-800/95 text-gray-400 hover:text-blue-300 active:text-blue-400 transition-colors text-xs"
          >
            <FiPlus className="w-4 h-4" />
            <span>Setlist</span>
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation();
              setShowActions(false);
              setShowGenerateModal(true);
            }}
            className="flex items-center gap-1.5 px-2 py-1.5 rounded bg-gray-800/95 text-gray-400 hover:text-purple-300 active:text-purple-400 transition-colors text-xs"
          >
            <FiMusic className="w-4 h-4" />
            <span>Key</span>
          </button>
        </div>
      </div>

      {showGenerateModal && (
        <GenerateModal
          songTitle={song.title}
          defaultConcertKey={defaultConcertKey}
          instrument={instrument}
          onClose={() => setShowGenerateModal(false)}
          onGenerated={(url) => {
            setShowGenerateModal(false);
            onOpenPdfUrl(url);
          }}
        />
      )}
    </>
  );
}
