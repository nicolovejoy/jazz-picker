import { useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { api } from '@/services/api';
import { formatKey, concertToWritten, type Instrument } from '@/types/catalog';
import { useUserProfile } from '@/contexts/UserProfileContext';

// All 12 concert keys in circle of fifths order
const CONCERT_KEYS = [
  { value: 'c', label: 'C' },
  { value: 'g', label: 'G' },
  { value: 'd', label: 'D' },
  { value: 'a', label: 'A' },
  { value: 'e', label: 'E' },
  { value: 'b', label: 'B' },
  { value: 'fs', label: 'F♯' },
  { value: 'df', label: 'D♭' },
  { value: 'af', label: 'A♭' },
  { value: 'ef', label: 'E♭' },
  { value: 'bf', label: 'B♭' },
  { value: 'f', label: 'F' },
];

interface TransposeModalProps {
  songTitle: string;
  defaultConcertKey?: string;
  instrument: Instrument;
  onClose: () => void;
  onTransposed: (url: string, concertKey: string) => void;
}

export function TransposeModal({
  songTitle,
  defaultConcertKey = 'c',
  instrument,
  onClose,
  onTransposed,
}: TransposeModalProps) {
  const queryClient = useQueryClient();
  const { getPreferredKey } = useUserProfile();
  const initialKey = getPreferredKey(songTitle, defaultConcertKey);
  const [selectedConcertKey, setSelectedConcertKey] = useState(initialKey);
  const [isTransposing, setIsTransposing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);

  // Get written key for display (for transposing instruments)
  const getWrittenKeyDisplay = (concertKey: string) => {
    if (instrument.transposition === 'C') {
      return formatKey(concertKey);
    }
    const writtenKey = concertToWritten(concertKey, instrument.transposition);
    return `${formatKey(writtenKey)} (Concert ${formatKey(concertKey)})`;
  };

  const handleTranspose = async () => {
    setIsTransposing(true);
    setError(null);
    setProgress(0);

    const progressInterval = setInterval(() => {
      setProgress((prev) => Math.min(prev + 8, 90));
    }, 500);

    try {
      const result = await api.generatePDF(
        songTitle,
        selectedConcertKey,
        instrument.transposition,
        instrument.clef,
        instrument.label
      );
      clearInterval(progressInterval);
      setProgress(100);

      // Invalidate cached keys
      queryClient.invalidateQueries({ queryKey: ['cachedKeys', songTitle] });

      setTimeout(() => {
        onTransposed(result.url, selectedConcertKey);
      }, 300);
    } catch (err) {
      clearInterval(progressInterval);
      setError(err instanceof Error ? err.message : 'Transposition failed');
      setIsTransposing(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-gray-900 rounded-xl border border-white/20 p-6 max-w-md w-full">
        <div className="flex justify-between items-start mb-6">
          <div>
            <h2 className="text-lg font-semibold text-white">Transpose</h2>
            <p className="text-sm text-gray-400 mt-1">{songTitle}</p>
          </div>
          <button
            onClick={onClose}
            disabled={isTransposing}
            className="text-gray-400 hover:text-white transition-colors disabled:opacity-50"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {!isTransposing ? (
          <>
            {/* Key Selection */}
            <div className="mb-6">
              <label className="block text-sm text-gray-400 mb-2">
                {instrument.transposition === 'C' ? 'Key' : 'Concert Key'}
              </label>
              <div className="grid grid-cols-6 gap-2">
                {CONCERT_KEYS.map((key) => (
                  <button
                    key={key.value}
                    onClick={() => setSelectedConcertKey(key.value)}
                    className={`py-2 text-sm rounded-lg border transition-all ${
                      selectedConcertKey === key.value
                        ? 'bg-blue-500 border-blue-400 text-white'
                        : 'bg-white/5 border-white/10 text-gray-300 hover:border-white/30'
                    }`}
                  >
                    {key.label}
                  </button>
                ))}
              </div>
              {instrument.transposition !== 'C' && (
                <p className="text-xs text-gray-500 mt-2">
                  Written key: {getWrittenKeyDisplay(selectedConcertKey)}
                </p>
              )}
            </div>

            {error && (
              <div className="mb-4 p-3 bg-red-500/20 border border-red-500/50 rounded-lg text-red-300 text-sm">
                {error}
              </div>
            )}

            <button
              onClick={handleTranspose}
              className="w-full py-3 bg-blue-500 hover:bg-blue-600 text-white rounded-lg font-medium transition-colors"
            >
              Transpose
            </button>
          </>
        ) : (
          <div className="py-4">
            <div className="mb-2 flex justify-between text-sm">
              <span className="text-gray-400">Transposing...</span>
              <span className="text-blue-400">{progress}%</span>
            </div>
            <div className="h-2 bg-white/10 rounded-full overflow-hidden">
              <div
                className="h-full bg-blue-500 transition-all duration-300"
                style={{ width: `${progress}%` }}
              />
            </div>
            <p className="text-xs text-gray-500 mt-3 text-center">
              This may take a few seconds...
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
