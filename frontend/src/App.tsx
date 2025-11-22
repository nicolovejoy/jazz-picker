import { useState, useEffect, useRef, useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { Header } from './components/Header';
import { SongList } from './components/SongList';
import { PDFViewer } from './components/PDFViewer';
import { useSongsV2 } from './hooks/useSongsV2';
import { api } from './services/api';
import type { InstrumentType, SingerRangeType, Variation, SongSummary } from '@/types/catalog';

function App() {
  const [instrument, setInstrument] = useState<InstrumentType>('All');
  const [singerRange, setSingerRange] = useState<SingerRangeType>('All');
  const [selectedVariation, setSelectedVariation] = useState<Variation | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [allSongs, setAllSongs] = useState<SongSummary[]>([]);
  const [hasMore, setHasMore] = useState(true);
  const [page, setPage] = useState(0);
  const [expandedSong, setExpandedSong] = useState<string | null>(null);
  const LIMIT = 50;

  const queryClient = useQueryClient();
  const observerTarget = useRef<HTMLDivElement>(null);

  const { data, isLoading, isError, isFetching } = useSongsV2({
    limit: LIMIT,
    offset: page * LIMIT,
    query: searchQuery,
    instrument,
    singerRange
  });

  // Pre-fetch next page
  useEffect(() => {
    if (data && hasMore && !isFetching) {
      const nextPage = page + 1;
      const nextOffset = nextPage * LIMIT;

      // Only pre-fetch if there's potentially more data
      if (nextOffset < data.total) {
        queryClient.prefetchQuery({
          queryKey: ['songs', LIMIT, nextOffset, searchQuery, instrument, singerRange],
          queryFn: () => api.getSongsV2(LIMIT, nextOffset, searchQuery, instrument, singerRange),
        });
      }
    }
  }, [data, page, hasMore, isFetching, searchQuery, instrument, singerRange, queryClient]);

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
    setPage(0);
    setAllSongs([]);
    setExpandedSong(null);
  }, []);

  const handleInstrumentChange = useCallback((inst: InstrumentType) => {
    setInstrument(inst);
    setPage(0);
    setAllSongs([]);
    setExpandedSong(null);
  }, []);

  const handleRangeChange = useCallback((range: SingerRangeType) => {
    setSingerRange(range);
    setPage(0);
    setAllSongs([]);
    setExpandedSong(null);
  }, []);

  const handleEnterPress = useCallback(async () => {
    // Only handle if exactly 1 song in results
    if (allSongs.length !== 1) return;

    const song = allSongs[0];

    // Fetch song details
    try {
      const songDetail = await api.getSongV2(song.title);

      if (songDetail.variations.length === 1) {
        // Single variation: open PDF directly
        setSelectedVariation(songDetail.variations[0] as any);
      } else if (songDetail.variations.length > 1) {
        // Multiple variations: expand the card
        setExpandedSong(song.title);
      }
    } catch (error) {
      console.error('Failed to fetch song details:', error);
    }
  }, [allSongs]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 text-white">
      <Header
        totalSongs={data?.total || 0}
        instrument={instrument}
        singerRange={singerRange}
        searchQuery={searchQuery}
        onInstrumentChange={handleInstrumentChange}
        onSingerRangeChange={handleRangeChange}
        onSearch={handleSearch}
        onEnterPress={handleEnterPress}
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
              instrument={instrument}
              singerRange={singerRange}
              searchQuery={searchQuery}
              expandedSong={expandedSong}
              onToggleExpand={(title) => setExpandedSong(expandedSong === title ? null : title)}
              onSelectVariation={setSelectedVariation}
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

      {selectedVariation && (
        <PDFViewer
          variation={selectedVariation}
          onClose={() => setSelectedVariation(null)}
        />
      )}
    </div>
  );
}

export default App;
