import { useState } from 'react';
import { api } from '@/services/api';
import type { PdfMetadata } from '../App';

interface SetlistProps {
  onOpenPdfUrl: (url: string, metadata?: PdfMetadata) => void;
  onClose: () => void;
}

const SETLIST = [
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
  { title: "Is You Is or Is You Ain't My Baby", key: "a", clef: "treble" },
  { title: "Dream a Little Dream of Me", key: "c", clef: "treble" },
  { title: "C'est Si Bon", key: "ef", clef: "treble" },
  { title: "The In Crowd", key: "d", clef: "treble" },
];

const KEY_DISPLAY: Record<string, string> = {
  'c': 'C', 'cs': 'C#', 'df': 'Db', 'd': 'D', 'ds': 'D#', 'ef': 'Eb',
  'e': 'E', 'f': 'F', 'fs': 'F#', 'gf': 'Gb', 'g': 'G', 'gs': 'G#',
  'af': 'Ab', 'a': 'A', 'as': 'A#', 'bf': 'Bb', 'b': 'B'
};

export function Setlist({ onOpenPdfUrl, onClose }: SetlistProps) {
  const [loading, setLoading] = useState<number | null>(null);

  const handleSongClick = async (index: number) => {
    const song = SETLIST[index];
    setLoading(index);
    try {
      const result = await api.generatePDF(song.title, song.key, song.clef as 'treble' | 'bass');
      onOpenPdfUrl(result.url, {
        songTitle: song.title,
        key: song.key,
        clef: song.clef,
        cached: result.cached,
        generationTimeMs: result.generation_time_ms,
      });
    } catch (err) {
      console.error('Failed to load:', err);
      alert(`Could not load "${song.title}". Check if it exists in the catalog.`);
    } finally {
      setLoading(null);
    }
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
                  : 'bg-white/5 border-white/10 hover:bg-white/10 hover:border-white/20'
              }`}
            >
              <span className="text-gray-500 text-sm w-6">{index + 1}</span>
              <span className="flex-1 text-white font-medium">{song.title}</span>
              <span className="text-gray-400 text-sm">{KEY_DISPLAY[song.key] || song.key}</span>
              {loading === index && (
                <div className="animate-spin rounded-full h-5 w-5 border-2 border-blue-400 border-t-transparent" />
              )}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
