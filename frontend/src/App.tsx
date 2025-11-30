import { useState, useEffect, useRef, useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { Header } from './components/Header';
import { SongList } from './components/SongList';
import { PDFViewer } from './components/PDFViewer';
import { WelcomeScreen } from './components/WelcomeScreen';
import { AuthGate } from './components/AuthGate';
import { SetlistManager } from './components/SetlistManager';
import { SetlistViewer } from './components/SetlistViewer';
import { AboutPage } from './components/AboutPage';
import type { Setlist } from '@/types/setlist';
import { useSongsV2 } from './hooks/useSongsV2';
import { useAuth } from './contexts/AuthContext';
import { api } from './services/api';
import type { InstrumentType, SongSummary } from '@/types/catalog';

export interface PdfMetadata {
  songTitle: string;
  key: string;
  clef: string;
  cached: boolean;
  generationTimeMs: number;
}

export interface SetlistNavigation {
  currentIndex: number;
  totalSongs: number;
  onPrevSong: () => void;
  onNextSong: () => void;
}

const STORAGE_KEY = 'jazz-picker-instrument';

function getStoredInstrument(): InstrumentType | null {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored && ['C', 'Bb', 'Eb', 'Bass', 'All'].includes(stored)) {
      return stored as InstrumentType;
    }
  } catch {
    // localStorage not available
  }
  return null;
}

function App() {
  const { user, loading, signOut } = useAuth();
  const storedInstrument = getStoredInstrument();
  const [instrument, setInstrument] = useState<InstrumentType | null>(storedInstrument);
  const [pdfUrl, setPdfUrl] = useState<string | null>(null);
  const [pdfMetadata, setPdfMetadata] = useState<PdfMetadata | null>(null);
  const [showSetlistManager, setShowSetlistManager] = useState(false);
  const [activeSetlist, setActiveSetlist] = useState<Setlist | null>(null);
  const [setlistNav, setSetlistNav] = useState<SetlistNavigation | null>(null);
  const [showAbout, setShowAbout] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [allSongs, setAllSongs] = useState<SongSummary[]>([]);
  const [hasMore, setHasMore] = useState(true);
  const [page, setPage] = useState(0);
  const LIMIT = 50;

  const queryClient = useQueryClient();
  const observerTarget = useRef<HTMLDivElement>(null);

  const { data, isLoading, isError, isFetching } = useSongsV2({
    limit: LIMIT,
    offset: page * LIMIT,
    query: searchQuery,
    instrument: instrument || 'All',
  });

  // Pre-fetch next page
  useEffect(() => {
    if (data && hasMore && !isFetching && instrument) {
      const nextPage = page + 1;
      const nextOffset = nextPage * LIMIT;
      const inst = instrument || 'All';

      // Only pre-fetch if there's potentially more data
      if (nextOffset < data.total) {
        queryClient.prefetchQuery({
          queryKey: ['songs', LIMIT, nextOffset, searchQuery, inst],
          queryFn: () => api.getSongsV2(LIMIT, nextOffset, searchQuery, inst),
        });
      }
    }
  }, [data, page, hasMore, isFetching, searchQuery, instrument, queryClient]);

  // Reset songs when filters change
  useEffect(() => {
    setPage(0);
    setAllSongs([]);
  }, [searchQuery, instrument]);

  // Accumulate songs as pages load
  useEffect(() => {
    if (data?.songs) {
      if (page === 0) {
        // Reset on first page (new search/filter)
        setAllSongs(data.songs);
      } else {
        // Append to existing songs
        setAllSongs(prev => [...prev, ...data.songs]);
      }

      // Check if there are more pages
      const loadedCount = (page + 1) * LIMIT;
      setHasMore(loadedCount < data.total);
    }
  }, [data, page]);

  // Infinite scroll observer
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && hasMore && !isFetching) {
          setPage(prev => prev + 1);
        }
      },
      { threshold: 0.1 }
    );

    const currentTarget = observerTarget.current;
    if (currentTarget) {
      observer.observe(currentTarget);
    }

    return () => {
      if (currentTarget) {
        observer.unobserve(currentTarget);
      }
    };
  }, [hasMore, isFetching]);

  const handleSearch = useCallback((query: string) => {
    setSearchQuery(query);
  }, []);

  const handleInstrumentChange = useCallback((inst: InstrumentType) => {
    setInstrument(inst);
    try {
      localStorage.setItem(STORAGE_KEY, inst);
    } catch {
      // localStorage not available
    }
  }, []);

  const handleResetInstrument = useCallback(() => {
    setInstrument(null);
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch {
      // localStorage not available
    }
  }, []);

  const handleOpenPdfUrl = useCallback((url: string, metadata?: PdfMetadata) => {
    setPdfUrl(url);
    setPdfMetadata(metadata || null);
  }, []);

  const handleEnterPress = useCallback(async () => {
    // Only handle if exactly 1 song in results
    if (allSongs.length !== 1) return;

    const song = allSongs[0];

    // Fetch cached info and generate PDF in default key
    try {
      const cachedInfo = await api.getCachedKeys(song.title);
      const clef = cachedInfo.default_clef === 'bass' ? 'bass' : 'treble';
      const result = await api.generatePDF(
        song.title,
        cachedInfo.default_key,
        clef
      );
      setPdfUrl(result.url);
      setPdfMetadata({
        songTitle: song.title,
        key: cachedInfo.default_key,
        clef,
        cached: result.cached,
        generationTimeMs: result.generation_time_ms,
      });
    } catch (error) {
      console.error('Failed to open song:', error);
    }
  }, [allSongs]);

  // Show loading spinner while checking auth
  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-400"></div>
      </div>
    );
  }

  // Show auth gate if not logged in
  if (!user) {
    return <AuthGate />;
  }

  // Show welcome screen if no instrument selected
  if (!instrument) {
    return <WelcomeScreen onSelectInstrument={handleInstrumentChange} />;
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 text-white">
      <Header
        totalSongs={data?.total || 0}
        instrument={instrument}
        searchQuery={searchQuery}
        onInstrumentChange={handleInstrumentChange}
        onSearch={handleSearch}
        onEnterPress={handleEnterPress}
        onResetInstrument={handleResetInstrument}
        onOpenSetlist={() => setShowSetlistManager(true)}
        onLogout={signOut}
        onOpenAbout={() => setShowAbout(true)}
      />

      <main className="container mx-auto px-4 py-8 pb-24">
        {isError ? (
          <div className="text-center py-20 text-red-400">
            <p className="text-xl">Error loading songs</p>
            <p className="text-sm mt-2">Please try again later</p>
          </div>
        ) : isLoading && page === 0 ? (
          <div className="flex justify-center py-20">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-400"></div>
          </div>
        ) : (
          <>
            <SongList
              songs={allSongs}
              searchQuery={searchQuery}
              onOpenPdfUrl={handleOpenPdfUrl}
            />

            {/* Infinite Scroll Trigger */}
            {hasMore && (
              <div ref={observerTarget} className="flex justify-center py-8">
                {isFetching && (
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
                )}
              </div>
            )}

            {/* End of list message */}
            {!hasMore && allSongs.length > 0 && (
              <div className="text-center py-8 text-gray-500">
                <p>End of list ({allSongs.length} songs)</p>
              </div>
            )}
          </>
        )}
      </main>

      {showSetlistManager && !activeSetlist && (
        <SetlistManager
          onSelectSetlist={(setlist) => setActiveSetlist(setlist)}
          onClose={() => setShowSetlistManager(false)}
        />
      )}

      {activeSetlist && (
        <SetlistViewer
          setlist={activeSetlist}
          onOpenPdfUrl={handleOpenPdfUrl}
          onSetlistNav={setSetlistNav}
          onBack={() => setActiveSetlist(null)}
        />
      )}

      {pdfUrl && (
        <PDFViewer
          pdfUrl={pdfUrl}
          metadata={pdfMetadata}
          setlistNav={setlistNav}
          onClose={() => {
            setPdfUrl(null);
            setPdfMetadata(null);
          }}
        />
      )}

      {showAbout && (
        <AboutPage onClose={() => setShowAbout(false)} />
      )}
    </div>
  );
}

export default App;
