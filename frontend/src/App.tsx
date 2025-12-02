import { useState, useEffect, useRef, useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { Capacitor } from '@capacitor/core';
import { Header } from './components/Header';
import { BottomNav, type AppContext } from './components/BottomNav';
import { SongList } from './components/SongList';
import { PDFViewer } from './components/PDFViewer';
import { WelcomeScreen } from './components/WelcomeScreen';
import { AuthGate } from './components/AuthGate';
import { SetlistManager } from './components/SetlistManager';
import { SetlistViewer } from './components/SetlistViewer';
import { AboutPage } from './components/AboutPage';
import { AddToSetlistModal } from './components/AddToSetlistModal';
import NativePDF from './plugins/NativePDF';
import type { Setlist } from '@/types/setlist';
import { useSongsV2 } from './hooks/useSongsV2';
import { useAuth } from './contexts/AuthContext';
import { api } from './services/api';
import { setlistService } from './services/setlistService';
import { getInstrumentById, type Instrument, type SongSummary } from '@/types/catalog';

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

const STORAGE_KEY = 'jazz-picker-instrument-id';

function getStoredInstrument(): Instrument | null {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      const instrument = getInstrumentById(stored);
      if (instrument) return instrument;
    }
  } catch {
    // localStorage not available
  }
  return null;
}

function App() {
  const { user, loading, signOut } = useAuth();
  const storedInstrument = getStoredInstrument();
  const [instrument, setInstrument] = useState<Instrument | null>(storedInstrument);
  const [pdfUrl, setPdfUrl] = useState<string | null>(null);
  const [pdfMetadata, setPdfMetadata] = useState<PdfMetadata | null>(null);
  const [activeContext, setActiveContext] = useState<AppContext>('browse');
  const [activeSetlist, setActiveSetlist] = useState<Setlist | null>(null);
  const [setlistNav, setSetlistNav] = useState<SetlistNavigation | null>(null);
  const [showAbout, setShowAbout] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [allSongs, setAllSongs] = useState<SongSummary[]>([]);
  const [hasMore, setHasMore] = useState(true);
  const [page, setPage] = useState(0);
  const [songToAdd, setSongToAdd] = useState<SongSummary | null>(null);
  const LIMIT = 50;

  const queryClient = useQueryClient();
  const observerTarget = useRef<HTMLDivElement>(null);

  const { data, isLoading, isError, isFetching } = useSongsV2({
    limit: LIMIT,
    offset: page * LIMIT,
    query: searchQuery,
  });

  // Pre-fetch next page
  useEffect(() => {
    if (data && hasMore && !isFetching) {
      const nextPage = page + 1;
      const nextOffset = nextPage * LIMIT;

      // Only pre-fetch if there's potentially more data
      if (nextOffset < data.total) {
        queryClient.prefetchQuery({
          queryKey: ['songs', LIMIT, nextOffset, searchQuery],
          queryFn: () => api.getSongsV2(LIMIT, nextOffset, searchQuery),
        });
      }
    }
  }, [data, page, hasMore, isFetching, searchQuery, queryClient]);

  // Reset songs when search changes
  useEffect(() => {
    setPage(0);
    setAllSongs([]);
  }, [searchQuery]);

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

  // Handle URL params for deep linking
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const setlistId = params.get('setlist');

    if (setlistId && user && instrument) {
      setlistService.getSetlist(setlistId).then(setlist => {
        if (setlist) {
          setActiveSetlist(setlist);
          setActiveContext('setlist');
        }
      }).catch(err => {
        console.error('Failed to load setlist from URL:', err);
      });
    }
  }, [user, instrument]);

  // Update URL when setlist changes
  useEffect(() => {
    const url = new URL(window.location.href);
    if (activeSetlist) {
      url.searchParams.set('setlist', activeSetlist.id);
    } else {
      url.searchParams.delete('setlist');
    }
    window.history.replaceState({}, '', url.toString());
  }, [activeSetlist]);

  const handleSearch = useCallback((query: string) => {
    setSearchQuery(query);
  }, []);

  const handleInstrumentChange = useCallback((inst: Instrument) => {
    setInstrument(inst);
    try {
      localStorage.setItem(STORAGE_KEY, inst.id);
    } catch {
      // localStorage not available
    }
  }, []);

  const handleOpenPdfUrl = useCallback(async (url: string, metadata?: PdfMetadata) => {
    // On native iOS, use the native PDF viewer
    if (Capacitor.isNativePlatform()) {
      try {
        await NativePDF.open({
          url,
          title: metadata?.songTitle,
          key: metadata?.key,
        });
        return; // Native viewer handles everything
      } catch (error) {
        console.error('[App] Native PDF error, falling back to web:', error);
        // Fall through to web viewer
      }
    }

    // Web: use the React PDF viewer
    setPdfUrl(url);
    setPdfMetadata(metadata || null);
  }, []);

  const handleEnterPress = useCallback(async () => {
    // Only handle if exactly 1 song in results and we have an instrument
    if (allSongs.length !== 1 || !instrument) return;

    const song = allSongs[0];

    // Generate PDF in default concert key for user's instrument
    try {
      const result = await api.generatePDF(
        song.title,
        song.default_key,
        instrument.transposition,
        instrument.clef,
        instrument.label
      );
      setPdfUrl(result.url);
      setPdfMetadata({
        songTitle: song.title,
        key: song.default_key,
        clef: instrument.clef,
        cached: result.cached,
        generationTimeMs: result.generation_time_ms,
      });
    } catch (error) {
      console.error('Failed to open song:', error);
    }
  }, [allSongs, instrument]);

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
    <div className="min-h-full bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 text-white pb-20">
      {/* Header only shows on Browse context */}
      {activeContext === 'browse' && (
        <Header
          searchQuery={searchQuery}
          onSearch={handleSearch}
          onEnterPress={handleEnterPress}
        />
      )}

      <main className={`container mx-auto px-4 ${activeContext === 'browse' ? 'pt-20 pb-4' : 'py-4'}`}>
        {/* Browse Context */}
        {activeContext === 'browse' && (
          <>
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
                  instrument={instrument}
                  onOpenPdfUrl={handleOpenPdfUrl}
                  onAddToSetlist={setSongToAdd}
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
          </>
        )}

        {/* Spin Context (Placeholder) */}
        {activeContext === 'spin' && (
          <div className="flex flex-col items-center justify-center min-h-[60vh] text-center">
            <div className="text-6xl mb-4">🎲</div>
            <h2 className="text-2xl font-bold mb-2">Spin the Dial</h2>
            <p className="text-gray-400 max-w-xs">
              Random song practice mode. Coming soon.
            </p>
          </div>
        )}

        {/* Setlist Context */}
        {activeContext === 'setlist' && (
          <>
            {activeSetlist ? (
              <SetlistViewer
                setlist={activeSetlist}
                instrument={instrument}
                onOpenPdfUrl={handleOpenPdfUrl}
                onSetlistNav={setSetlistNav}
                onBack={() => setActiveSetlist(null)}
              />
            ) : (
              <SetlistManager
                onSelectSetlist={(setlist) => setActiveSetlist(setlist)}
                onClose={() => setActiveContext('browse')}
              />
            )}
          </>
        )}

        {/* Menu Context */}
        {activeContext === 'menu' && (
          <div className="max-w-md mx-auto py-8 space-y-4">
            <h2 className="text-xl font-bold mb-6 text-gray-300">Settings & More</h2>

            {/* Settings Section */}
            <div className="space-y-2">
              <button
                onClick={() => setInstrument(null)}
                className="w-full flex items-center justify-between p-4 bg-white/5 hover:bg-white/10 rounded border border-white/10 transition-colors"
              >
                <span>Instrument</span>
                <span className="text-blue-400">{instrument.label}</span>
              </button>

              <button
                onClick={() => setShowAbout(true)}
                className="w-full flex items-center justify-between p-4 bg-white/5 hover:bg-white/10 rounded border border-white/10 transition-colors"
              >
                <span>About</span>
                <span className="text-gray-500">→</span>
              </button>
            </div>

            {/* Account Section */}
            <div className="pt-4 border-t border-white/10">
              <p className="text-sm text-gray-500 mb-3">{user.email}</p>
              <button
                onClick={signOut}
                className="w-full p-3 text-red-400 hover:bg-red-500/10 rounded border border-red-500/20 transition-colors"
              >
                Sign Out
              </button>
            </div>

            {/* Version Info */}
            <div className="pt-4 text-center text-xs text-gray-600">
              Jazz Picker v2.0 · Piano House Project
            </div>
          </div>
        )}
      </main>

      {/* Bottom Navigation - Always visible except in PDF Viewer */}
      {!pdfUrl && (
        <BottomNav activeContext={activeContext} onContextChange={setActiveContext} />
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

      {songToAdd && (
        <AddToSetlistModal
          song={songToAdd}
          onClose={() => setSongToAdd(null)}
          onAdded={(setlist) => {
            setActiveSetlist(setlist);
            setActiveContext('setlist');
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
