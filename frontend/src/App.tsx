import { useState, useEffect, useRef, useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { Header } from './components/Header';
import { BottomNav, type AppContext } from './components/BottomNav';
import { SongList } from './components/SongList';
import { PDFViewer } from './components/PDFViewer';
import { WelcomeScreen } from './components/WelcomeScreen';
import { SetlistManager } from './components/SetlistManager';
import { SetlistViewer } from './components/SetlistViewer';
import { AboutPage } from './components/AboutPage';
import { AddToSetlistModal } from './components/AddToSetlistModal';
import type { Setlist } from '@/types/setlist';
import { useSongsV2 } from './hooks/useSongsV2';
import { api } from './services/api';
import { setlistService } from './services/setlistService';
import { getInstrumentById, type Instrument, type SongSummary } from '@/types/catalog';
import type { CropBounds } from '@/types/pdf';

export interface PdfMetadata {
  songTitle: string;
  key: string;
  clef: string;
  cached: boolean;
  generationTimeMs: number;
  crop?: CropBounds;
}

export interface SetlistNavigation {
  currentIndex: number;
  totalSongs: number;
  onPrevSong: () => void;
  onNextSong: () => void;
}

export interface CatalogNavigation {
  currentIndex: number;
  totalSongs: number;
  catalog: SongSummary[];
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
  const [addToSetlistKey, setAddToSetlistKey] = useState<string | undefined>(undefined);
  const [catalog, setCatalog] = useState<SongSummary[]>([]);
  const [catalogNav, setCatalogNav] = useState<CatalogNavigation | null>(null);
  const [isSpinning, setIsSpinning] = useState(false);
  const [isPdfTransitioning, setIsPdfTransitioning] = useState(false);
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
    if (data?.songs && !isFetching) {
      if (page === 0) {
        setAllSongs(data.songs);
      } else {
        setAllSongs(prev => {
          const existingTitles = new Set(prev.map(s => s.title));
          const newSongs = data.songs.filter(s => !existingTitles.has(s.title));
          return [...prev, ...newSongs];
        });
      }

      const loadedCount = (page + 1) * LIMIT;
      setHasMore(loadedCount < data.total);
    }
  }, [data, page, isFetching]);

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

    if (setlistId && instrument) {
      setlistService.getSetlist(setlistId).then(setlist => {
        if (setlist) {
          setActiveSetlist(setlist);
          setActiveContext('setlist');
        }
      }).catch(err => {
        console.error('Failed to load setlist from URL:', err);
      });
    }
  }, [instrument]);

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

  // Fetch full catalog for navigation (Spin + alphabetical browsing)
  useEffect(() => {
    if (instrument) {
      api.getCatalog().then(response => {
        setCatalog(response.songs);
      }).catch(err => {
        console.error('Failed to load catalog:', err);
      });
    }
  }, [instrument]);

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

  // Use refs to access current nav state in callbacks
  const setlistNavRef = useRef(setlistNav);
  useEffect(() => {
    setlistNavRef.current = setlistNav;
  }, [setlistNav]);

  const catalogNavRef = useRef(catalogNav);
  useEffect(() => {
    catalogNavRef.current = catalogNav;
  }, [catalogNav]);

  // Ref to track current catalog index for navigation callbacks
  const catalogIndexRef = useRef<number>(0);

  // Navigate to adjacent song in catalog
  const navigateCatalog = useCallback(async (newIndex: number) => {
    if (!instrument || catalog.length === 0) return;
    if (newIndex < 0 || newIndex >= catalog.length) return;

    const song = catalog[newIndex];
    catalogIndexRef.current = newIndex;

    // Show loading overlay
    setIsPdfTransitioning(true);

    try {
      const result = await api.generatePDF(
        song.title,
        song.default_key,
        instrument.transposition,
        instrument.clef,
        instrument.label
      );

      const metadata: PdfMetadata = {
        songTitle: song.title,
        key: song.default_key,
        clef: instrument.clef,
        cached: result.cached,
        generationTimeMs: result.generation_time_ms,
        crop: result.crop,
      };

      // Update navigation state
      setCatalogNav({
        currentIndex: newIndex,
        totalSongs: catalog.length,
        catalog: catalog,
      });

      // Update PDF
      setPdfUrl(result.url);
      setPdfMetadata(metadata);
    } catch (error) {
      console.error('Failed to navigate catalog:', error);
    } finally {
      setIsPdfTransitioning(false);
    }
  }, [catalog, instrument]);

  const handleOpenPdfUrl = useCallback(async (url: string, metadata?: PdfMetadata, catalogIndex?: number) => {
    // Auto-detect catalog index from song title if not provided and not in setlist mode
    let effectiveCatalogIndex = catalogIndex;
    if (effectiveCatalogIndex === undefined && setlistNavRef.current === null && metadata?.songTitle && catalog.length > 0) {
      const foundIndex = catalog.findIndex(s => s.title === metadata.songTitle);
      if (foundIndex >= 0) {
        effectiveCatalogIndex = foundIndex;
        catalogIndexRef.current = foundIndex;
        setCatalogNav({
          currentIndex: foundIndex,
          totalSongs: catalog.length,
          catalog: catalog,
        });
      }
    }

    // Web: use the React PDF viewer
    setPdfUrl(url);
    setPdfMetadata(metadata || null);
  }, [catalog]);

  const handleEnterPress = useCallback(async () => {
    // Only handle if exactly 1 song in results and we have an instrument
    if (allSongs.length !== 1 || !instrument) return;

    const song = allSongs[0];

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
        crop: result.crop,
      });
    } catch (error) {
      console.error('Failed to open song:', error);
    }
  }, [allSongs, instrument]);

  // Create setlist-compatible navigation for catalog
  const catalogAsSetlistNav = useCallback((): SetlistNavigation | null => {
    if (catalogNav === null) return null;
    return {
      currentIndex: catalogNav.currentIndex,
      totalSongs: catalogNav.totalSongs,
      onPrevSong: () => navigateCatalog(catalogIndexRef.current - 1),
      onNextSong: () => navigateCatalog(catalogIndexRef.current + 1),
    };
  }, [catalogNav, navigateCatalog]);

  // Open a song from catalog with navigation context
  const openSongFromCatalog = useCallback(async (songIndex: number) => {
    if (!instrument || catalog.length === 0) return;

    const song = catalog[songIndex];
    if (!song) return;

    catalogIndexRef.current = songIndex;

    // Set up catalog navigation
    setCatalogNav({
      currentIndex: songIndex,
      totalSongs: catalog.length,
      catalog: catalog,
    });

    try {
      const result = await api.generatePDF(
        song.title,
        song.default_key,
        instrument.transposition,
        instrument.clef,
        instrument.label
      );

      const metadata: PdfMetadata = {
        songTitle: song.title,
        key: song.default_key,
        clef: instrument.clef,
        cached: result.cached,
        generationTimeMs: result.generation_time_ms,
        crop: result.crop,
      };

      await handleOpenPdfUrl(result.url, metadata, songIndex);
    } catch (error) {
      console.error('Failed to open song:', error);
    }
  }, [catalog, instrument, handleOpenPdfUrl]);

  // Spin: animate nav icon then pick a random song
  const handleSpin = useCallback(() => {
    if (catalog.length === 0 || isSpinning) return;

    setIsSpinning(true);

    setTimeout(() => {
      setIsSpinning(false);
      const randomIndex = Math.floor(Math.random() * catalog.length);
      openSongFromCatalog(randomIndex);
    }, 800);
  }, [catalog, openSongFromCatalog, isSpinning]);

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
            <h2 className="text-xl font-bold mb-6 text-gray-300">Settings</h2>

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

            {/* Version Info */}
            <div className="pt-4 text-center text-xs text-gray-600">
              Jazz Picker · Piano House Project
            </div>
          </div>
        )}
      </main>

      {/* Bottom Navigation - Always visible except in PDF Viewer */}
      {!pdfUrl && (
        <BottomNav
          activeContext={activeContext}
          onContextChange={setActiveContext}
          onSpin={handleSpin}
          isSpinning={isSpinning}
        />
      )}

      {pdfUrl && (
        <PDFViewer
          pdfUrl={pdfUrl}
          metadata={pdfMetadata}
          setlistNav={setlistNav || catalogAsSetlistNav()}
          isTransitioning={isPdfTransitioning}
          onClose={() => {
            setPdfUrl(null);
            setPdfMetadata(null);
            setCatalogNav(null);
          }}
          onAddToSetlist={pdfMetadata ? () => {
            // Find the song in catalog by title
            const song = catalog.find(s => s.title === pdfMetadata.songTitle);
            if (song) {
              setSongToAdd(song);
              setAddToSetlistKey(pdfMetadata.key);
            }
          } : undefined}
        />
      )}

      {songToAdd && (
        <AddToSetlistModal
          song={songToAdd}
          concertKey={addToSetlistKey}
          onClose={() => {
            setSongToAdd(null);
            setAddToSetlistKey(undefined);
          }}
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
