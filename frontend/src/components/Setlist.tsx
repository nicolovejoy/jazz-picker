import { useState, useEffect, useCallback, useRef } from 'react';
import { api } from '@/services/api';
import type { PdfMetadata, SetlistNavigation } from '../App';

interface SetlistProps {
  onOpenPdfUrl: (url: string, metadata?: PdfMetadata) => void;
  onSetlistNav: (nav: SetlistNavigation | null) => void;
  onClose: () => void;
}

interface SetlistSong {
  title: string;
  key: string;
  clef: string;
}

interface CachedPdf {
  blobUrl: string;
  metadata: PdfMetadata;
}

const SETLIST: SetlistSong[] = [
  { title: "Blue Bossa", key: "c", clef: "treble" },
  { title: "East of the Sun", key: "c", clef: "treble" },
  { title: "Peel Me a Grape", key: "a", clef: "treble" },
  { title: "The Thrill Is Gone", key: "g", clef: "treble" },
  { title: "Black Orpheus", key: "e", clef: "treble" },
  { title: "Fever", key: "a", clef: "treble" },
  { title: "I Fall In Love Too Easily", key: "bf", clef: "treble" },
  { title: "Blue Christmas", key: "c", clef: "treble" },
  { title: "I've Got My Love to Keep Me Warm", key: "af", clef: "treble" },
  { title: "Alright Okay You Win", key: "c", clef: "treble" },
  { title: "Almost Blue", key: "f", clef: "treble" },
  { title: "Black Coffee", key: "c", clef: "treble" },
  { title: "Is You Is or Is You Ain't (Ma' Baby)", key: "a", clef: "treble" },
  { title: "Dream a Little Dream of Me", key: "c", clef: "treble" },
  { title: "C'est Si Bon French", key: "ef", clef: "treble" },
  { title: "The In Crowd", key: "d", clef: "treble" },
];

const KEY_DISPLAY: Record<string, string> = {
  'c': 'C', 'cs': 'C#', 'df': 'Db', 'd': 'D', 'ds': 'D#', 'ef': 'Eb',
  'e': 'E', 'f': 'F', 'fs': 'F#', 'gf': 'Gb', 'g': 'G', 'gs': 'G#',
  'af': 'Ab', 'a': 'A', 'as': 'A#', 'bf': 'Bb', 'b': 'B'
};

export function Setlist({ onOpenPdfUrl, onSetlistNav, onClose }: SetlistProps) {
  const [loading, setLoading] = useState<number | null>(null);
  const [prefetchStatus, setPrefetchStatus] = useState<Record<number, 'pending' | 'loading' | 'done' | 'error'>>({});
  const [currentIndex, setCurrentIndex] = useState<number | null>(null);

  // In-memory cache of PDF blobs
  const pdfCache = useRef<Record<number, CachedPdf>>({});

  // Prefetch all PDFs in background on mount
  useEffect(() => {
    const prefetchAll = async () => {
      // Initialize all as pending
      const initialStatus: Record<number, 'pending' | 'loading' | 'done' | 'error'> = {};
      SETLIST.forEach((_, i) => { initialStatus[i] = 'pending'; });
      setPrefetchStatus(initialStatus);

      // Prefetch in parallel (but not all at once - batch of 4)
      const batchSize = 4;
      for (let i = 0; i < SETLIST.length; i += batchSize) {
        const batch = SETLIST.slice(i, i + batchSize);
        await Promise.all(
          batch.map(async (song, batchIndex) => {
            const index = i + batchIndex;
            setPrefetchStatus(prev => ({ ...prev, [index]: 'loading' }));

            try {
              // Get presigned URL
              const result = await api.generatePDF(song.title, song.key, song.clef as 'treble' | 'bass');

              // Fetch the actual PDF blob
              const response = await fetch(result.url);
              const blob = await response.blob();
              const blobUrl = URL.createObjectURL(blob);

              // Cache it
              pdfCache.current[index] = {
                blobUrl,
                metadata: {
                  songTitle: song.title,
                  key: song.key,
                  clef: song.clef,
                  cached: result.cached,
                  generationTimeMs: result.generation_time_ms,
                },
              };

              setPrefetchStatus(prev => ({ ...prev, [index]: 'done' }));
            } catch (err) {
              console.error(`Failed to prefetch ${song.title}:`, err);
              setPrefetchStatus(prev => ({ ...prev, [index]: 'error' }));
            }
          })
        );
      }
    };

    prefetchAll();

    // Cleanup blob URLs on unmount
    return () => {
      Object.values(pdfCache.current).forEach(cached => {
        URL.revokeObjectURL(cached.blobUrl);
      });
    };
  }, []);

  // Load a song by index and open the PDF
  const loadSong = useCallback(async (index: number) => {
    if (index < 0 || index >= SETLIST.length) return;

    const song = SETLIST[index];
    setCurrentIndex(index);

    // Check if already in cache - instant load!
    const cached = pdfCache.current[index];
    if (cached) {
      onOpenPdfUrl(cached.blobUrl, cached.metadata);
      return;
    }

    // Not in cache yet - fetch it
    setLoading(index);

    try {
      const result = await api.generatePDF(song.title, song.key, song.clef as 'treble' | 'bass');

      // Fetch and cache the blob
      const response = await fetch(result.url);
      const blob = await response.blob();
      const blobUrl = URL.createObjectURL(blob);

      const metadata: PdfMetadata = {
        songTitle: song.title,
        key: song.key,
        clef: song.clef,
        cached: result.cached,
        generationTimeMs: result.generation_time_ms,
      };

      pdfCache.current[index] = { blobUrl, metadata };
      setPrefetchStatus((prev) => ({ ...prev, [index]: 'done' }));
      onOpenPdfUrl(blobUrl, metadata);
    } catch (err) {
      console.error('Failed to load:', err);
      alert(`Could not load "${song.title}". Check if it exists in the catalog.`);
    } finally {
      setLoading(null);
    }
  }, [onOpenPdfUrl]);

  // Update navigation callbacks when currentIndex changes
  useEffect(() => {
    if (currentIndex !== null) {
      onSetlistNav({
        currentIndex,
        totalSongs: SETLIST.length,
        onPrevSong: () => {
          if (currentIndex > 0) {
            loadSong(currentIndex - 1);
          }
        },
        onNextSong: () => {
          if (currentIndex < SETLIST.length - 1) {
            loadSong(currentIndex + 1);
          }
        },
      });
    }
  }, [currentIndex, loadSong, onSetlistNav]);

  // Clear navigation when setlist closes
  useEffect(() => {
    return () => {
      onSetlistNav(null);
    };
  }, [onSetlistNav]);

  const handleSongClick = (index: number) => {
    loadSong(index);
  };

  return (
    <div className="fixed inset-0 bg-black/90 z-40 overflow-auto">
      <div className="max-w-2xl mx-auto p-4">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold text-white">Gig Setlist</h1>
          <button
            onClick={onClose}
            className="px-4 py-2 bg-white/10 hover:bg-white/20 rounded-lg text-white"
          >
            Back to Browse
          </button>
        </div>

        <div className="space-y-2">
          {SETLIST.map((song, index) => (
            <button
              key={index}
              onClick={() => handleSongClick(index)}
              disabled={loading !== null}
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
              <span className="text-gray-500 text-sm w-6">{index + 1}</span>
              <span className="flex-1 text-white font-medium">{song.title}</span>
              <span className="text-gray-400 text-sm">{KEY_DISPLAY[song.key] || song.key}</span>
              {loading === index ? (
                <div className="animate-spin rounded-full h-5 w-5 border-2 border-blue-400 border-t-transparent" />
              ) : prefetchStatus[index] === 'loading' ? (
                <div className="animate-spin rounded-full h-4 w-4 border-2 border-yellow-400/50 border-t-transparent" />
              ) : prefetchStatus[index] === 'done' ? (
                <span className="text-green-400 text-xs">Ready</span>
              ) : null}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
