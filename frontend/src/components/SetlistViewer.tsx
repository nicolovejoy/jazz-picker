import { useState, useEffect, useCallback, useRef } from 'react';
import { FiArrowLeft, FiTrash2 } from 'react-icons/fi';
import { api } from '@/services/api';
import { useSetlist, useRemoveSetlistItem } from '@/hooks/useSetlists';
import type { PdfMetadata, SetlistNavigation } from '../App';
import type { Setlist, SetlistItem } from '@/types/setlist';

interface SetlistViewerProps {
  setlist: Setlist;
  onOpenPdfUrl: (url: string, metadata?: PdfMetadata) => void;
  onSetlistNav: (nav: SetlistNavigation | null) => void;
  onBack: () => void;
}

interface CachedPdf {
  blobUrl: string;
  metadata: PdfMetadata;
}

// Resolved key/clef for each item (fetched from API)
interface ResolvedSongInfo {
  key: string;
  clef: 'treble' | 'bass';
}

const KEY_DISPLAY: Record<string, string> = {
  'c': 'C', 'cs': 'C#', 'df': 'Db', 'd': 'D', 'ds': 'D#', 'ef': 'Eb',
  'e': 'E', 'f': 'F', 'fs': 'F#', 'gf': 'Gb', 'g': 'G', 'gs': 'G#',
  'af': 'Ab', 'a': 'A', 'as': 'A#', 'bf': 'Bb', 'b': 'B'
};

export function SetlistViewer({ setlist, onOpenPdfUrl, onSetlistNav, onBack }: SetlistViewerProps) {
  const [loading, setLoading] = useState<number | null>(null);
  const [prefetchStatus, setPrefetchStatus] = useState<Record<number, 'pending' | 'loading' | 'done' | 'error'>>({});
  const [currentIndex, setCurrentIndex] = useState<number | null>(null);
  const [resolvedInfo, setResolvedInfo] = useState<Record<number, ResolvedSongInfo>>({});

  const { data: setlistWithItems, isLoading: isLoadingItems } = useSetlist(setlist.id);
  const removeItem = useRemoveSetlistItem();

  // In-memory cache of PDF blobs
  const pdfCache = useRef<Record<number, CachedPdf>>({});

  const items = setlistWithItems?.items || [];

  // Prefetch all PDFs in background when items load
  useEffect(() => {
    if (items.length === 0) return;

    const prefetchAll = async () => {
      // Initialize all as pending
      const initialStatus: Record<number, 'pending' | 'loading' | 'done' | 'error'> = {};
      items.forEach((_, i) => { initialStatus[i] = 'pending'; });
      setPrefetchStatus(initialStatus);

      // Prefetch in parallel (batches of 4)
      const batchSize = 4;
      for (let i = 0; i < items.length; i += batchSize) {
        const batch = items.slice(i, i + batchSize);
        await Promise.all(
          batch.map(async (item, batchIndex) => {
            const index = i + batchIndex;
            setPrefetchStatus(prev => ({ ...prev, [index]: 'loading' }));

            try {
              // Get the default key/clef for this song
              const cachedInfo = await api.getCachedKeys(item.song_title);
              const key = cachedInfo.default_key;
              const clef = cachedInfo.default_clef === 'bass' ? 'bass' : 'treble';

              // Store resolved info for display
              setResolvedInfo(prev => ({ ...prev, [index]: { key, clef } }));

              const result = await api.generatePDF(item.song_title, key, clef);

              const response = await fetch(result.url);
              const blob = await response.blob();
              const blobUrl = URL.createObjectURL(blob);

              pdfCache.current[index] = {
                blobUrl,
                metadata: {
                  songTitle: item.song_title,
                  key,
                  clef,
                  cached: result.cached,
                  generationTimeMs: result.generation_time_ms,
                },
              };

              setPrefetchStatus(prev => ({ ...prev, [index]: 'done' }));
            } catch (err) {
              console.error(`Failed to prefetch ${item.song_title}:`, err);
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
  }, [items]);

  const loadSong = useCallback(async (index: number) => {
    if (index < 0 || index >= items.length) return;

    const item = items[index];
    setCurrentIndex(index);

    // Check cache first
    const cached = pdfCache.current[index];
    if (cached) {
      onOpenPdfUrl(cached.blobUrl, cached.metadata);
      return;
    }

    setLoading(index);

    try {
      // Get the default key/clef for this song
      const cachedInfo = await api.getCachedKeys(item.song_title);
      const key = cachedInfo.default_key;
      const clef = cachedInfo.default_clef === 'bass' ? 'bass' : 'treble';

      setResolvedInfo(prev => ({ ...prev, [index]: { key, clef } }));

      const result = await api.generatePDF(item.song_title, key, clef);

      const response = await fetch(result.url);
      const blob = await response.blob();
      const blobUrl = URL.createObjectURL(blob);

      const metadata: PdfMetadata = {
        songTitle: item.song_title,
        key,
        clef,
        cached: result.cached,
        generationTimeMs: result.generation_time_ms,
      };

      pdfCache.current[index] = { blobUrl, metadata };
      setPrefetchStatus(prev => ({ ...prev, [index]: 'done' }));
      onOpenPdfUrl(blobUrl, metadata);
    } catch (err) {
      console.error('Failed to load:', err);
      alert(`Could not load "${item.song_title}". Check if it exists in the catalog.`);
    } finally {
      setLoading(null);
    }
  }, [items, onOpenPdfUrl]);

  // Update navigation callbacks when currentIndex changes
  useEffect(() => {
    if (currentIndex !== null && items.length > 0) {
      onSetlistNav({
        currentIndex,
        totalSongs: items.length,
        onPrevSong: () => {
          if (currentIndex > 0) {
            loadSong(currentIndex - 1);
          }
        },
        onNextSong: () => {
          if (currentIndex < items.length - 1) {
            loadSong(currentIndex + 1);
          }
        },
      });
    }
  }, [currentIndex, items.length, loadSong, onSetlistNav]);

  // Clear navigation when viewer closes
  useEffect(() => {
    return () => {
      onSetlistNav(null);
    };
  }, [onSetlistNav]);

  const handleRemoveItem = async (item: SetlistItem, index: number) => {
    try {
      await removeItem.mutateAsync({ itemId: item.id, setlistId: setlist.id });
      // Clear cached blob if exists
      if (pdfCache.current[index]) {
        URL.revokeObjectURL(pdfCache.current[index].blobUrl);
        delete pdfCache.current[index];
      }
    } catch (err) {
      console.error('Failed to remove item:', err);
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
                    <span className="flex-1 text-white font-medium">{item.song_title}</span>
                    {info && (
                      <span className="text-gray-400 text-sm">{KEY_DISPLAY[info.key] || info.key}</span>
                    )}
                    {loading === index ? (
                      <div className="animate-spin rounded-full h-5 w-5 border-2 border-blue-400 border-t-transparent" />
                    ) : prefetchStatus[index] === 'loading' ? (
                      <div className="animate-spin rounded-full h-4 w-4 border-2 border-yellow-400/50 border-t-transparent" />
                    ) : prefetchStatus[index] === 'done' ? (
                      <span className="text-green-400 text-xs">Ready</span>
                    ) : null}
                  </button>
                  <button
                    onClick={() => handleRemoveItem(item, index)}
                    disabled={removeItem.isPending}
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
