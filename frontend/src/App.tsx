import { useState, useEffect, useRef, useCallback } from 'react';
import { Routes, Route, useParams, useNavigate, useSearchParams } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { Header } from './components/Header';
import { BottomNav, type AppContext } from './components/BottomNav';
import { SongList } from './components/SongList';
import { PDFViewer } from './components/PDFViewer';
import { SetlistManager } from './components/SetlistManager';
import { SetlistViewer } from './components/SetlistViewer';
import { AboutPage } from './components/AboutPage';
import { SignIn } from './components/SignIn';
import { OnboardingModal } from './components/OnboardingModal';
import { InstrumentPickerModal } from './components/InstrumentPickerModal';
import { GroupsSection } from './components/GroupsSection';
import { JoinBandModal } from './components/JoinBandModal';
import { GrooveSyncFollower } from './components/GrooveSyncFollower';
import { GrooveSyncModal } from './components/GrooveSyncModal';
import { useAuth } from './contexts/AuthContext';
import { useUserProfile } from './contexts/UserProfileContext';
import { useGrooveSync } from './contexts/GrooveSyncContext';
import type { Setlist } from '@/types/setlist';
import { useSongsV2 } from './hooks/useSongsV2';
import { api } from './services/api';
import { getSetlist } from './services/setlistFirestoreService';
import { getInstrumentById, type Instrument, type SongSummary } from '@/types/catalog';
import type { CropBounds } from '@/types/pdf';
import { toSongSlug, findSongBySlug } from './utils/songSlug';

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

// Route component for /setlist/:id
function SetlistRoute({ onSetlistLoad }: { onSetlistLoad: (setlist: Setlist) => void }) {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { profile } = useUserProfile();
  const instrument = profile?.instrument ? getInstrumentById(profile.instrument) : null;

  useEffect(() => {
    if (!id || !instrument) return;

    getSetlist(id).then(setlist => {
      if (setlist) {
        onSetlistLoad(setlist);
      } else {
        console.error('Setlist not found:', id);
        navigate('/', { replace: true });
      }
    }).catch(err => {
      console.error('Failed to load setlist:', err);
      navigate('/', { replace: true });
    });
  }, [id, instrument, onSetlistLoad, navigate]);

  return null; // Loading is handled by parent
}

// Route component for /join/:code
function JoinRoute({ onJoinCode }: { onJoinCode: (code: string) => void }) {
  const { code } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const { profile } = useUserProfile();

  useEffect(() => {
    if (!code || !profile) return;

    onJoinCode(code);
    navigate('/', { replace: true });
  }, [code, profile, onJoinCode, navigate]);

  return null;
}

// Route component for /song/:slug
interface SongRouteProps {
  catalog: SongSummary[];
  instrument: Instrument | null;
  onOpenSong: (title: string, concertKey: string, octaveOffset: number) => void;
}

function SongRoute({ catalog, instrument, onOpenSong }: SongRouteProps) {
  const { slug } = useParams<{ slug: string }>();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();

  useEffect(() => {
    if (!slug || !instrument || catalog.length === 0) return;

    const song = findSongBySlug(catalog, slug);
    if (!song) {
      console.error('Song not found:', slug);
      navigate('/', { replace: true });
      return;
    }

    const key = searchParams.get('key') || song.default_key;
    const octave = parseInt(searchParams.get('octave') || '0', 10);

    onOpenSong(song.title, key, octave);
  }, [slug, catalog, instrument, searchParams, onOpenSong, navigate]);

  return null;
}

function App() {
  const navigate = useNavigate();
  const { user, loading: authLoading, signOut } = useAuth();
  const { profile, loading: profileLoading, updateProfile, setPreferredKey } = useUserProfile();
  const { isFollowing, activeSessions, startFollowing } = useGrooveSync();

  // Derive instrument from profile
  const instrument = profile?.instrument ? getInstrumentById(profile.instrument) : null;
  const [pdfUrl, setPdfUrl] = useState<string | null>(null);
  const [pdfMetadata, setPdfMetadata] = useState<PdfMetadata | null>(null);
  const [activeContext, setActiveContext] = useState<AppContext>('browse');
  const [activeSetlist, setActiveSetlist] = useState<Setlist | null>(null);
  const [setlistNav, setSetlistNav] = useState<SetlistNavigation | null>(null);
  const [showAbout, setShowAbout] = useState(false);
  const [showInstrumentPicker, setShowInstrumentPicker] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [allSongs, setAllSongs] = useState<SongSummary[]>([]);
  const [hasMore, setHasMore] = useState(true);
  const [page, setPage] = useState(0);
  const [catalog, setCatalog] = useState<SongSummary[]>([]);
  const [catalogNav, setCatalogNav] = useState<CatalogNavigation | null>(null);
  const [isSpinning, setIsSpinning] = useState(false);
  const [isPdfTransitioning, setIsPdfTransitioning] = useState(false);
  const [pendingJoinCode, setPendingJoinCode] = useState<string | null>(null);
  const [grooveSyncModalDismissed, setGrooveSyncModalDismissed] = useState(false);
  const [grooveSyncSessionDismissedId, setGrooveSyncSessionDismissedId] = useState<string | null>(null);
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

  // Legacy URL param redirect (for old ?setlist= and ?join= links)
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const setlistId = params.get('setlist');
    const joinCode = params.get('join');

    if (setlistId) {
      // Redirect to path-based route
      window.location.replace(`/setlist/${setlistId}`);
      return;
    }

    if (joinCode) {
      // Redirect to path-based route
      window.location.replace(`/join/${joinCode}`);
      return;
    }
  }, []);

  // Reset Groove Sync modal dismissed state when closing PDF viewer
  const prevPdfUrlRef = useRef<string | null>(null);
  useEffect(() => {
    // When transitioning from PDF to non-PDF, reset the dismissed state
    if (prevPdfUrlRef.current && !pdfUrl) {
      setGrooveSyncModalDismissed(false);
    }
    prevPdfUrlRef.current = pdfUrl;
  }, [pdfUrl]);

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

  const handleInstrumentChange = useCallback(async (inst: Instrument) => {
    try {
      await updateProfile({ instrument: inst.id });
    } catch (err) {
      console.error('Failed to update instrument:', err);
    }
  }, [updateProfile]);

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

      // Update URL (replace since we're navigating within songs)
      const slug = toSongSlug(song.title);
      navigate(`/song/${slug}`, { replace: true });

      // Update PDF
      setPdfUrl(result.url);
      setPdfMetadata(metadata);
    } catch (error) {
      console.error('Failed to navigate catalog:', error);
    } finally {
      setIsPdfTransitioning(false);
    }
  }, [catalog, instrument, navigate]);

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

    // Update URL when opening from browse (not setlist)
    if (setlistNavRef.current === null && metadata?.songTitle && metadata?.key) {
      const slug = toSongSlug(metadata.songTitle);
      const song = catalog.find(s => s.title === metadata.songTitle);
      const defaultKey = song?.default_key || metadata.key;
      // Only include key param if different from default
      const keyParam = metadata.key !== defaultKey ? `?key=${metadata.key}` : '';
      navigate(`/song/${slug}${keyParam}`);
    }

    // Web: use the React PDF viewer
    setPdfUrl(url);
    setPdfMetadata(metadata || null);
  }, [catalog, navigate]);

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

  // Handle setlist load from route
  const handleSetlistLoad = useCallback((setlist: Setlist) => {
    setActiveSetlist(setlist);
    setActiveContext('setlist');
  }, []);

  // Handle setlist selection with navigation
  const handleSelectSetlist = useCallback((setlist: Setlist) => {
    setActiveSetlist(setlist);
    navigate(`/setlist/${setlist.id}`);
  }, [navigate]);

  // Handle back from setlist with navigation
  const handleSetlistBack = useCallback(() => {
    setActiveSetlist(null);
    navigate('/');
  }, [navigate]);

  // Handle song open from /song/:slug route
  const handleOpenSongFromRoute = useCallback(async (title: string, concertKey: string, octaveOffset: number) => {
    if (!instrument) return;

    try {
      const result = await api.generatePDF(
        title,
        concertKey,
        instrument.transposition,
        instrument.clef,
        instrument.label,
        octaveOffset
      );

      const metadata: PdfMetadata = {
        songTitle: title,
        key: concertKey,
        clef: instrument.clef,
        cached: result.cached,
        generationTimeMs: result.generation_time_ms,
        crop: result.crop,
      };

      // Find catalog index for navigation
      const catalogIndex = catalog.findIndex(s => s.title === title);
      if (catalogIndex >= 0) {
        catalogIndexRef.current = catalogIndex;
        setCatalogNav({
          currentIndex: catalogIndex,
          totalSongs: catalog.length,
          catalog: catalog,
        });
      }

      setPdfUrl(result.url);
      setPdfMetadata(metadata);
    } catch (error) {
      console.error('Failed to open song from route:', error);
      navigate('/', { replace: true });
    }
  }, [instrument, catalog, navigate]);

  // Show loading while checking auth/profile state
  if (authLoading || profileLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-400"></div>
      </div>
    );
  }

  // Show sign in if not authenticated
  if (!user) {
    return <SignIn />;
  }

  // Show onboarding modal if no profile exists
  if (!profile) {
    return <OnboardingModal />;
  }

  // At this point we have a profile but instrument lookup failed - shouldn't happen
  if (!instrument) {
    return <OnboardingModal />;
  }

  return (
    <div className="min-h-full bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 text-white pb-20">
      {/* Route handlers for deep links */}
      <Routes>
        <Route path="/setlist/:id" element={<SetlistRoute onSetlistLoad={handleSetlistLoad} />} />
        <Route path="/join/:code" element={<JoinRoute onJoinCode={setPendingJoinCode} />} />
        <Route path="/song/:slug" element={<SongRoute catalog={catalog} instrument={instrument} onOpenSong={handleOpenSongFromRoute} />} />
        <Route path="*" element={null} />
      </Routes>

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
                onBack={handleSetlistBack}
              />
            ) : (
              <SetlistManager
                onSelectSetlist={handleSelectSetlist}
                onClose={() => setActiveContext('browse')}
              />
            )}
          </>
        )}

        {/* Menu Context */}
        {activeContext === 'menu' && (
          <div className="max-w-md mx-auto py-8 space-y-6">
            <h2 className="text-xl font-bold mb-6 text-gray-300">Settings</h2>

            {/* Account Section */}
            <div className="space-y-2">
              <h3 className="text-sm font-medium text-gray-400 uppercase tracking-wide">Account</h3>
              <div className="p-4 bg-white/5 rounded border border-white/10">
                <span className="text-gray-400 text-sm">Signed in as</span>
                <p className="text-white truncate">{user.email || user.displayName || 'Unknown'}</p>
              </div>

              <button
                onClick={() => setShowInstrumentPicker(true)}
                className="w-full flex items-center justify-between p-4 bg-white/5 hover:bg-white/10 rounded border border-white/10 transition-colors"
              >
                <span>Instrument</span>
                <span className="text-blue-400">{instrument.label}</span>
              </button>
            </div>

            {/* Groups Section */}
            <GroupsSection />

            {/* Other */}
            <div className="space-y-2">
              <button
                onClick={() => setShowAbout(true)}
                className="w-full flex items-center justify-between p-4 bg-white/5 hover:bg-white/10 rounded border border-white/10 transition-colors"
              >
                <span>About</span>
                <span className="text-gray-500">→</span>
              </button>

              <button
                onClick={signOut}
                className="w-full flex items-center justify-between p-4 bg-red-500/10 hover:bg-red-500/20 rounded border border-red-500/30 text-red-400 transition-colors"
              >
                <span>Sign Out</span>
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
          onContextChange={(context) => {
            if (context === 'setlist' && activeContext === 'setlist' && activeSetlist) {
              // Second tap on setlist tab goes back to setlist list
              setActiveSetlist(null);
            } else {
              setActiveContext(context);
            }
          }}
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
            // Navigate to / when closing from browse mode (not setlist)
            if (setlistNav === null && catalogNav !== null) {
              navigate('/');
            }
            setCatalogNav(null);
          }}
          instrument={instrument}
          onKeyChange={(url, newKey) => {
            setPdfUrl(url);
            if (pdfMetadata) {
              setPdfMetadata({ ...pdfMetadata, key: newKey });
              // Get default key from catalog for sparse storage
              const song = catalog.find(s => s.title === pdfMetadata.songTitle);
              const defaultKey = song?.default_key || 'c';
              setPreferredKey(pdfMetadata.songTitle, newKey, defaultKey).catch(console.error);

              // Update URL when in browse mode (not setlist)
              if (setlistNav === null) {
                const slug = toSongSlug(pdfMetadata.songTitle);
                const keyParam = newKey !== defaultKey ? `?key=${newKey}` : '';
                navigate(`/song/${slug}${keyParam}`, { replace: true });
              }
            }
          }}
        />
      )}

      {showAbout && (
        <AboutPage onClose={() => setShowAbout(false)} />
      )}

      {showInstrumentPicker && instrument && (
        <InstrumentPickerModal
          currentInstrument={instrument}
          onSelect={(inst) => {
            handleInstrumentChange(inst);
            setShowInstrumentPicker(false);
          }}
          onClose={() => setShowInstrumentPicker(false)}
        />
      )}

      {pendingJoinCode && (
        <JoinBandModal
          code={pendingJoinCode}
          onClose={() => setPendingJoinCode(null)}
          onJoined={() => setPendingJoinCode(null)}
        />
      )}

      {/* Groove Sync Follower View */}
      {isFollowing && <GrooveSyncFollower />}

      {/* Groove Sync Modal */}
      {!isFollowing && !pdfUrl && !grooveSyncModalDismissed && activeSessions.length > 0 && activeSessions[0].leaderId !== user?.uid && grooveSyncSessionDismissedId !== activeSessions[0].leaderId && (
        <GrooveSyncModal
          session={activeSessions[0]}
          onJoin={() => startFollowing(activeSessions[0])}
          onDismiss={() => setGrooveSyncModalDismissed(true)}
          onDismissSession={() => setGrooveSyncSessionDismissedId(activeSessions[0].leaderId)}
        />
      )}
    </div>
  );
}

export default App;
