import { useState } from 'react';
import { Header } from '@/components/Header';
import { SongList } from '@/components/SongList';
import { PDFViewer } from '@/components/PDFViewer';
import { useSongs } from '@/hooks/useSongs';
import type { InstrumentType, SingerRangeType, Variation } from '@/types/catalog';

function App() {
  const { data: songs, isLoading, error } = useSongs();
  const [instrument, setInstrument] = useState<InstrumentType>('C');
  const [singerRange, setSingerRange] = useState<SingerRangeType>('Alto/Mezzo/Soprano');
  const [selectedVariation, setSelectedVariation] = useState<Variation | null>(null);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-400 mx-auto mb-4"></div>
          <p className="text-gray-400 text-xl">Loading songs...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <p className="text-red-400 text-xl font-semibold mb-2">⚠️ Error</p>
          <p className="text-gray-300">Failed to load songs. Please try again.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen p-4 md:p-6 lg:p-8">
      <div className="max-w-7xl mx-auto">
        <Header
          totalSongs={songs?.length || 0}
          instrument={instrument}
          singerRange={singerRange}
          onInstrumentChange={setInstrument}
          onSingerRangeChange={setSingerRange}
        />

        <SongList
          songs={songs || []}
          instrument={instrument}
          singerRange={singerRange}
          onSelectVariation={setSelectedVariation}
        />
      </div>

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
