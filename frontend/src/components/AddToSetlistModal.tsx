import { useState } from 'react';
import { FiX, FiPlus } from 'react-icons/fi';
import { useSetlists } from '@/contexts/SetlistContext';
import type { Setlist } from '@/types/setlist';
import type { SongSummary } from '@/types/catalog';

interface AddToSetlistModalProps {
  song: SongSummary;
  concertKey?: string; // Override song.default_key when adding from PDF viewer
  onClose: () => void;
  onAdded: (setlist: Setlist) => void;
}

export function AddToSetlistModal({ song, concertKey, onClose, onAdded }: AddToSetlistModalProps) {
  const [newSetlistName, setNewSetlistName] = useState('');
  const [creating, setCreating] = useState(false);
  const [addingToId, setAddingToId] = useState<string | null>(null);

  const { setlists, loading, createSetlist, addItem } = useSetlists();

  const handleCreateSetlist = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newSetlistName.trim()) return;

    setCreating(true);
    try {
      const newSetlistId = await createSetlist(newSetlistName);
      setNewSetlistName('');
      // Auto-add to the new setlist
      await handleAddToSetlist(newSetlistId);
    } catch (error) {
      console.error('Failed to create setlist:', error);
      setCreating(false);
    }
  };

  const handleAddToSetlist = async (setlistId: string) => {
    setAddingToId(setlistId);
    try {
      await addItem(setlistId, {
        songTitle: song.title,
        concertKey: concertKey || song.default_key,
      });
      const setlist = setlists.find(s => s.id === setlistId);
      if (setlist) {
        onAdded(setlist);
      }
      onClose();
    } catch (error) {
      console.error('Failed to add song to setlist:', error);
      setAddingToId(null);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-gray-900 border border-white/10 rounded-2xl w-full max-w-md overflow-hidden shadow-2xl">
        <div className="p-4 border-b border-white/10 flex justify-between items-center bg-white/5">
          <h3 className="text-lg font-bold text-white">Add to Setlist</h3>
          <button onClick={onClose} className="p-2 hover:bg-white/10 rounded-full transition-colors">
            <FiX className="text-white text-lg" />
          </button>
        </div>

        <div className="p-4">
          <p className="text-gray-400 mb-4">
            Adding <span className="text-white font-medium">{song.title}</span> to...
          </p>

          {/* Create New Inline */}
          <form onSubmit={handleCreateSetlist} className="mb-4 flex gap-2">
            <input
              type="text"
              value={newSetlistName}
              onChange={(e) => setNewSetlistName(e.target.value)}
              placeholder="Create new setlist..."
              className="flex-1 bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 transition-colors"
            />
            <button
              type="submit"
              disabled={!newSetlistName.trim() || creating}
              className="bg-blue-600 hover:bg-blue-500 disabled:opacity-50 disabled:cursor-not-allowed text-white px-4 py-2 rounded-lg font-medium transition-colors"
            >
              {creating ? '...' : <FiPlus />}
            </button>
          </form>

          {/* List */}
          <div className="max-h-60 overflow-y-auto space-y-2">
            {loading ? (
              <div className="text-center py-8">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400 mx-auto"></div>
              </div>
            ) : setlists.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                No setlists found. Create one above!
              </div>
            ) : (
              setlists.map(setlist => (
                <button
                  key={setlist.id}
                  onClick={() => handleAddToSetlist(setlist.id)}
                  disabled={addingToId === setlist.id}
                  className="w-full flex items-center justify-between p-3 bg-white/5 hover:bg-white/10 rounded-xl transition-colors text-left group"
                >
                  <div>
                    <div className="font-medium text-white">{setlist.name}</div>
                  </div>
                  {addingToId === setlist.id ? (
                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-400"></div>
                  ) : (
                    <FiPlus className="text-gray-400 group-hover:text-white transition-colors" />
                  )}
                </button>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
