import { useState, useEffect, useCallback, useRef } from 'react';
import { FiArrowLeft, FiTrash2, FiLink, FiCheck, FiChevronUp, FiChevronDown } from 'react-icons/fi';
import { api } from '@/services/api';
import { useSetlist, useSetlists } from '@/contexts/SetlistContext';
import { formatKey, type Instrument } from '@/types/catalog';
import type { PdfMetadata, SetlistNavigation } from '../App';
import type { Setlist, SetlistItem } from '@/types/setlist';

interface SetlistViewerProps {
  setlist: Setlist;
  instrument: Instrument;
  onOpenPdfUrl: (url: string, metadata?: PdfMetadata) => void;
  onSetlistNav: (nav: SetlistNavigation | null) => void;
  onBack: () => void;
}

interface CachedPdf {
  blobUrl: string;
  metadata: PdfMetadata;
}

// Resolved concert key for each item
interface ResolvedSongInfo {
  concertKey: string;
}

export function SetlistViewer({ setlist, instrument, onOpenPdfUrl, onSetlistNav, onBack }: SetlistViewerProps) {
  const [loading, setLoading] = useState<number | null>(null);
  const [prefetchStatus, setPrefetchStatus] = useState<Record<number, 'pending' | 'loading' | 'done' | 'error'>>({});
  const [currentIndex, setCurrentIndex] = useState<number | null>(null);
  const [resolvedInfo, setResolvedInfo] = useState<Record<number, ResolvedSongInfo>>({});
  const [copied, setCopied] = useState(false);
  const [isRemoving, setIsRemoving] = useState(false);

  const { setlist: setlistWithItems, loading: isLoadingItems } = useSetlist(setlist.id);
  const { removeItem, updateItem } = useSetlists();

  // In-memory cache of PDF blobs
  const pdfCache = useRef<Record<number, CachedPdf>>({});

  const items = setlistWithItems?.items || [];

  // Prefetch all PDFs in background when items load
  useEffect(() => {
    if (items.length === 0) return;

    const prefetchAll = async () => {
      // Initialize all as pending (skip set breaks)
      const initialStatus: Record<number, 'pending' | 'loading' | 'done' | 'error'> = {};
      items.forEach((item, i) => {
        if (!item.isSetBreak) {
          initialStatus[i] = 'pending';
        }
      });
      setPrefetchStatus(initialStatus);

      // Filter to songs only for prefetching
      const songItems = items.map((item, index) => ({ item, index })).filter(({ item }) => !item.isSetBreak);

      // Prefetch in parallel (batches of 4)
      const batchSize = 4;
      for (let i = 0; i < songItems.length; i += batchSize) {
        const batch = songItems.slice(i, i + batchSize);
        await Promise.all(
          batch.map(async ({ item, index }) => {
            setPrefetchStatus(prev => ({ ...prev, [index]: 'loading' }));

            try {
              // Use stored concertKey if available, otherwise fetch default
              let concertKey = item.concertKey;
              if (!concertKey) {
                const cachedInfo = await api.getCachedKeys(item.songTitle, instrument.transposition, instrument.clef);
                concertKey = cachedInfo.default_key;
              }

              // Store resolved info for display
              setResolvedInfo(prev => ({ ...prev, [index]: { concertKey } }));

              const result = await api.generatePDF(
                item.songTitle,
                concertKey,
                instrument.transposition,
                instrument.clef,
                instrument.label,
                item.octaveOffset
              );

              // Prefetch as blob for faster display
              const response = await fetch(result.url);
              const blob = await response.blob();
              const blobUrl = URL.createObjectURL(blob);

              pdfCache.current[index] = {
                blobUrl,
                metadata: {
                  songTitle: item.songTitle,
                  key: concertKey,
                  clef: instrument.clef,
                  cached: result.cached,
                  generationTimeMs: result.generation_time_ms,
                  crop: result.crop,
                },
              };

              setPrefetchStatus(prev => ({ ...prev, [index]: 'done' }));
            } catch (err) {
              console.error(`Failed to prefetch ${item.songTitle}:`, err);
              setPrefetchStatus(prev => ({ ...prev, [index]: 'error' }));
            }
          })
        );
      }
    };

    prefetchAll();

    return () => {
      Object.values(pdfCache.current).forEach(cached => {
        URL.revokeObjectURL(cached.blobUrl);
      });
    };
  }, [items, instrument]);

  const loadSong = useCallback(async (index: number) => {
    if (index < 0 || index >= items.length) return;

    const item = items[index];
    if (item.isSetBreak) return; // Can't load a set break
    setCurrentIndex(index);

    // Check cache first
    const cached = pdfCache.current[index];
    if (cached) {
      onOpenPdfUrl(cached.blobUrl, cached.metadata);
      return;
    }

    setLoading(index);

    try {
      // Use stored concertKey if available, otherwise fetch default
      let concertKey = item.concertKey;
      if (!concertKey) {
        const cachedInfo = await api.getCachedKeys(item.songTitle, instrument.transposition, instrument.clef);
        concertKey = cachedInfo.default_key;
      }

      setResolvedInfo(prev => ({ ...prev, [index]: { concertKey } }));

      const result = await api.generatePDF(
        item.songTitle,
        concertKey,
        instrument.transposition,
        instrument.clef,
        instrument.label,
        item.octaveOffset
      );

      const metadata: PdfMetadata = {
        songTitle: item.songTitle,
        key: concertKey,
        clef: instrument.clef,
        cached: result.cached,
        generationTimeMs: result.generation_time_ms,
        crop: result.crop,
      };

      // Convert to blob for caching
      const response = await fetch(result.url);
      const blob = await response.blob();
      const blobUrl = URL.createObjectURL(blob);

      pdfCache.current[index] = { blobUrl, metadata };
      setPrefetchStatus(prev => ({ ...prev, [index]: 'done' }));

      onOpenPdfUrl(blobUrl, metadata);
    } catch (err) {
      console.error('Failed to load:', err);
      alert(`Could not load "${item.songTitle}". Check if it exists in the catalog.`);
    } finally {
      setLoading(null);
    }
  }, [items, instrument, onOpenPdfUrl]);

  // Update navigation callbacks when currentIndex changes
  useEffect(() => {
    if (currentIndex !== null && items.length > 0) {
      // Get song-only indices for navigation
      const songIndices = items.map((item, i) => ({ item, i })).filter(({ item }) => !item.isSetBreak).map(({ i }) => i);
      const currentSongPosition = songIndices.indexOf(currentIndex);

      onSetlistNav({
        currentIndex: currentSongPosition >= 0 ? currentSongPosition : 0,
        totalSongs: songIndices.length,
        onPrevSong: () => {
          if (currentSongPosition > 0) {
            loadSong(songIndices[currentSongPosition - 1]);
          }
        },
        onNextSong: () => {
          if (currentSongPosition < songIndices.length - 1) {
            loadSong(songIndices[currentSongPosition + 1]);
          }
        },
      });
    }
  }, [currentIndex, items, loadSong, onSetlistNav]);

  // Clear navigation when viewer closes
  useEffect(() => {
    return () => {
      onSetlistNav(null);
    };
  }, [onSetlistNav]);

  const handleRemoveItem = async (item: SetlistItem, index: number) => {
    setIsRemoving(true);
    try {
      await removeItem(setlist.id, item.id);
      // Clear cached blob if exists
      if (pdfCache.current[index]) {
        URL.revokeObjectURL(pdfCache.current[index].blobUrl);
        delete pdfCache.current[index];
      }
    } catch (err) {
      console.error('Failed to remove item:', err);
    } finally {
      setIsRemoving(false);
    }
  };

  const handleOctaveChange = async (item: SetlistItem, index: number, delta: number) => {
    const newOffset = (item.octaveOffset || 0) + delta;
    if (newOffset < -2 || newOffset > 2) return;

    try {
      await updateItem(setlist.id, item.id, { octaveOffset: newOffset });
      // Clear cached PDF so it regenerates with new octave
      if (pdfCache.current[index]) {
        URL.revokeObjectURL(pdfCache.current[index].blobUrl);
        delete pdfCache.current[index];
      }
      setPrefetchStatus(prev => ({ ...prev, [index]: 'pending' }));
    } catch (err) {
      console.error('Failed to update octave:', err);
    }
  };

  const handleCopyLink = async () => {
    const url = `${window.location.origin}?setlist=${setlist.id}`;
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Failed to copy link:', err);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/90 z-40 overflow-auto">
      <div className="max-w-2xl mx-auto p-4">
        <div className="flex justify-between items-center mb-6">
          <div className="flex items-center gap-3">
            <button
              onClick={onBack}
              className="p-2 bg-white/10 hover:bg-white/20 rounded-lg text-white"
              aria-label="Back to setlists"
            >
              <FiArrowLeft />
            </button>
            <h1 className="text-2xl font-bold text-white">{setlist.name}</h1>
          </div>
          <button
            onClick={handleCopyLink}
            className="flex items-center gap-2 px-3 py-2 bg-white/10 hover:bg-white/20 rounded-lg text-white text-sm transition-colors"
          >
            {copied ? <FiCheck className="text-green-400" /> : <FiLink />}
            {copied ? 'Copied!' : 'Copy Link'}
          </button>
        </div>

        {isLoadingItems && (
          <div className="flex justify-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
          </div>
        )}

        {!isLoadingItems && items.length === 0 && (
          <div className="text-center py-12 text-gray-500">
            <p>This setlist is empty</p>
            <p className="text-sm mt-1">Add songs from the browse view</p>
          </div>
        )}

        {items.length > 0 && (
          <div className="space-y-2">
            {items.map((item, index) => {
              // Render set breaks as visual dividers
              if (item.isSetBreak) {
                return (
                  <div key={item.id} className="flex items-center gap-4 py-2">
                    <div className="flex-1 h-px bg-gray-600" />
                    <span className="text-gray-500 text-sm">Set Break</span>
                    <div className="flex-1 h-px bg-gray-600" />
                    <button
                      onClick={() => handleRemoveItem(item, index)}
                      disabled={isRemoving}
                      className="p-2 text-gray-600 hover:text-red-400 transition-colors"
                      aria-label="Remove set break"
                    >
                      <FiTrash2 />
                    </button>
                  </div>
                );
              }

              const info = resolvedInfo[index];
              return (
                <div
                  key={item.id}
                  className={`w-full p-4 rounded-lg border text-left flex items-center gap-4 transition-all ${
                    loading === index
                      ? 'bg-blue-500/20 border-blue-500/50'
                      : prefetchStatus[index] === 'done'
                      ? 'bg-green-500/10 border-green-500/30 hover:bg-green-500/20 hover:border-green-500/50'
                      : prefetchStatus[index] === 'loading'
                      ? 'bg-yellow-500/5 border-yellow-500/20'
                      : 'bg-white/5 border-white/10 hover:bg-white/10 hover:border-white/20'
                  }`}
                >
                  <button
                    onClick={() => loadSong(index)}
                    disabled={loading !== null}
                    className="flex-1 flex items-center gap-4"
                  >
                    <span className="text-gray-500 text-sm w-6">{index + 1}</span>
                    <span className="flex-1 text-white font-medium">{item.songTitle}</span>
                    {info && (
                      <span className="text-gray-400 text-sm">{formatKey(info.concertKey)}</span>
                    )}
                    {item.octaveOffset ? (
                      <span className="text-orange-400 text-xs">
                        {item.octaveOffset > 0 ? `+${item.octaveOffset}` : item.octaveOffset} oct
                      </span>
                    ) : null}
                    {loading === index ? (
                      <div className="animate-spin rounded-full h-5 w-5 border-2 border-blue-400 border-t-transparent" />
                    ) : prefetchStatus[index] === 'loading' ? (
                      <div className="animate-spin rounded-full h-4 w-4 border-2 border-yellow-400/50 border-t-transparent" />
                    ) : prefetchStatus[index] === 'done' ? (
                      <span className="text-green-400 text-xs">Ready</span>
                    ) : null}
                  </button>
                  <div className="flex flex-col">
                    <button
                      onClick={() => handleOctaveChange(item, index, 1)}
                      disabled={(item.octaveOffset || 0) >= 2}
                      className="p-1 text-gray-500 hover:text-white disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                      aria-label="Octave up"
                    >
                      <FiChevronUp size={14} />
                    </button>
                    <button
                      onClick={() => handleOctaveChange(item, index, -1)}
                      disabled={(item.octaveOffset || 0) <= -2}
                      className="p-1 text-gray-500 hover:text-white disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                      aria-label="Octave down"
                    >
                      <FiChevronDown size={14} />
                    </button>
                  </div>
                  <button
                    onClick={() => handleRemoveItem(item, index)}
                    disabled={isRemoving}
                    className="p-2 text-gray-500 hover:text-red-400 transition-colors"
                    aria-label="Remove from setlist"
                  >
                    <FiTrash2 />
                  </button>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
