import { useState } from 'react';
import { Header } from './components/Header';
import { SongList } from './components/SongList';
import { PDFViewer } from './components/PDFViewer';
import { useSongsV2 } from './hooks/useSongsV2';
import type { InstrumentType, SingerRangeType, Variation } from '@/types/catalog';

function App() {
  const [instrument, setInstrument] = useState<InstrumentType>('All');
  const [singerRange, setSingerRange] = useState<SingerRangeType>('All');
  const [selectedVariation, setSelectedVariation] = useState<Variation | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [page, setPage] = useState(0);
  const LIMIT = 50;

  const { data, isLoading, isError } = useSongsV2({
    limit: LIMIT,
    offset: page * LIMIT,
    query: searchQuery,
    instrument,
    singerRange
  });

  const handleSearch = (query: string) => {
    setSearchQuery(query);
    setPage(0); // Reset to first page on search
  };

  const handleInstrumentChange = (inst: InstrumentType) => {
    setInstrument(inst);
    setPage(0);
  };

  const handleRangeChange = (range: SingerRangeType) => {
    setSingerRange(range);
    setPage(0);
  };

  const totalPages = data ? Math.ceil(data.total / LIMIT) : 0;

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 text-white">
      <Header
        totalSongs={data?.total || 0}
        instrument={instrument}
        singerRange={singerRange}
        onInstrumentChange={handleInstrumentChange}
        onSingerRangeChange={handleRangeChange}
      />

      <main className="container mx-auto px-4 py-8 pb-24">
        {isError ? (
          <div className="text-center py-20 text-red-400">
            <p className="text-xl">Error loading songs</p>
            <p className="text-sm mt-2">Please try again later</p>
          </div>
        ) : isLoading ? (
          <div className="flex justify-center py-20">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-400"></div>
          </div>
        ) : (
          <>
            <SongList
              songs={data?.songs || []}
              instrument={instrument}
              singerRange={singerRange}
              onSelectVariation={setSelectedVariation}
              onSearch={handleSearch}
            />

            {/* Pagination Controls */}
            {totalPages > 1 && (
              <div className="flex justify-center items-center gap-4 mt-8">
                <button
                  onClick={() => setPage((p) => Math.max(0, p - 1))}
                  disabled={page === 0}
                  className="px-4 py-2 bg-white/10 hover:bg-white/20 disabled:opacity-30 disabled:cursor-not-allowed rounded-lg transition-colors"
                >
                  Previous
                </button>
                <span className="text-gray-400">
                  Page {page + 1} of {totalPages}
                </span>
                <button
                  onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
                  disabled={page >= totalPages - 1}
                  className="px-4 py-2 bg-white/10 hover:bg-white/20 disabled:opacity-30 disabled:cursor-not-allowed rounded-lg transition-colors"
                >
                  Next
                </button>
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
