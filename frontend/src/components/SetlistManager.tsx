import { useState } from 'react';
import { FiPlus, FiTrash2, FiMusic, FiEdit2 } from 'react-icons/fi';
import { useSetlists } from '@/contexts/SetlistContext';
import type { Setlist } from '@/types/setlist';

interface SetlistManagerProps {
  onSelectSetlist: (setlist: Setlist) => void;
  onClose: () => void;
}

export function SetlistManager({ onSelectSetlist, onClose }: SetlistManagerProps) {
  const [newSetlistName, setNewSetlistName] = useState('');
  const [isCreating, setIsCreating] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);
  const [renaming, setRenaming] = useState<{ id: string; name: string } | null>(null);
  const [isPending, setIsPending] = useState(false);

  const { setlists, loading, createSetlist, updateSetlist, deleteSetlist } = useSetlists();

  const handleCreate = async () => {
    if (!newSetlistName.trim()) return;

    setIsPending(true);
    try {
      const id = await createSetlist(newSetlistName.trim());
      const created: Setlist = {
        id,
        name: newSetlistName.trim(),
        ownerId: '',
        createdAt: new Date(),
        updatedAt: new Date(),
        items: [],
      };
      setNewSetlistName('');
      setIsCreating(false);
      onSelectSetlist(created);
    } catch (err) {
      console.error('Failed to create setlist:', err);
    } finally {
      setIsPending(false);
    }
  };

  const handleDelete = async (id: string) => {
    setIsPending(true);
    try {
      await deleteSetlist(id);
      setDeleteConfirm(null);
    } catch (err) {
      console.error('Failed to delete setlist:', err);
    } finally {
      setIsPending(false);
    }
  };

  const handleRename = async () => {
    if (!renaming || !renaming.name.trim()) return;

    setIsPending(true);
    try {
      await updateSetlist(renaming.id, { name: renaming.name.trim() });
      setRenaming(null);
    } catch (err) {
      console.error('Failed to rename setlist:', err);
    } finally {
      setIsPending(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/90 z-40 overflow-auto">
      <div className="max-w-2xl mx-auto p-4">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold text-white">Setlists</h1>
          <button
            onClick={onClose}
            className="px-4 py-2 bg-white/10 hover:bg-white/20 rounded-lg text-white"
          >
            Back to Browse
          </button>
        </div>

        {/* Create New Setlist */}
        {isCreating ? (
          <div className="mb-6 p-4 bg-white/5 border border-white/10 rounded-lg">
            <input
              type="text"
              value={newSetlistName}
              onChange={(e) => setNewSetlistName(e.target.value)}
              placeholder="Setlist name..."
              className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 mb-3"
              autoFocus
              onKeyDown={(e) => {
                if (e.key === 'Enter') handleCreate();
                if (e.key === 'Escape') setIsCreating(false);
              }}
            />
            <div className="flex gap-2">
              <button
                onClick={handleCreate}
                disabled={!newSetlistName.trim() || isPending}
                className="px-4 py-2 bg-blue-500 hover:bg-blue-600 disabled:bg-blue-500/50 rounded-lg text-white font-medium"
              >
                {isPending ? 'Creating...' : 'Create'}
              </button>
              <button
                onClick={() => setIsCreating(false)}
                className="px-4 py-2 bg-white/10 hover:bg-white/20 rounded-lg text-white"
              >
                Cancel
              </button>
            </div>
          </div>
        ) : (
          <button
            onClick={() => setIsCreating(true)}
            className="w-full mb-6 p-4 border-2 border-dashed border-white/20 hover:border-blue-500/50 rounded-lg text-gray-400 hover:text-white flex items-center justify-center gap-2 transition-colors"
          >
            <FiPlus className="text-xl" />
            <span>Create New Setlist</span>
          </button>
        )}

        {/* Loading State */}
        {loading && (
          <div className="flex justify-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
          </div>
        )}

        {/* Empty State */}
        {!loading && setlists.length === 0 && (
          <div className="text-center py-12 text-gray-500">
            <FiMusic className="text-4xl mx-auto mb-3 opacity-50" />
            <p>No setlists yet</p>
            <p className="text-sm mt-1">Create one to get started</p>
          </div>
        )}

        {/* Setlist List */}
        {setlists.length > 0 && (
          <div className="space-y-2">
            {setlists.map((setlist) => (
              <div
                key={setlist.id}
                className="p-4 bg-white/5 border border-white/10 hover:bg-white/10 hover:border-white/20 rounded-lg flex items-center gap-4 transition-all"
              >
                {renaming?.id === setlist.id ? (
                  <div className="flex-1 flex items-center gap-2">
                    <input
                      type="text"
                      value={renaming.name}
                      onChange={(e) => setRenaming({ ...renaming, name: e.target.value })}
                      className="flex-1 px-3 py-1 bg-white/10 border border-white/20 rounded text-white focus:outline-none focus:border-blue-500"
                      autoFocus
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') handleRename();
                        if (e.key === 'Escape') setRenaming(null);
                      }}
                    />
                    <button
                      onClick={handleRename}
                      disabled={!renaming.name.trim() || isPending}
                      className="px-3 py-1 bg-blue-500 hover:bg-blue-600 disabled:bg-blue-500/50 rounded text-white text-sm"
                    >
                      {isPending ? '...' : 'Save'}
                    </button>
                    <button
                      onClick={() => setRenaming(null)}
                      className="px-3 py-1 bg-white/10 hover:bg-white/20 rounded text-white text-sm"
                    >
                      Cancel
                    </button>
                  </div>
                ) : (
                  <>
                    <button
                      onClick={() => onSelectSetlist(setlist)}
                      className="flex-1 text-left"
                    >
                      <div className="text-white font-medium">{setlist.name}</div>
                      <div className="text-gray-500 text-sm">
                        Updated {setlist.updatedAt.toLocaleDateString()}
                      </div>
                    </button>

                    {deleteConfirm === setlist.id ? (
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => handleDelete(setlist.id)}
                          disabled={isPending}
                          className="px-3 py-1 bg-red-500 hover:bg-red-600 rounded text-white text-sm"
                        >
                          {isPending ? '...' : 'Delete'}
                        </button>
                        <button
                          onClick={() => setDeleteConfirm(null)}
                          className="px-3 py-1 bg-white/10 hover:bg-white/20 rounded text-white text-sm"
                        >
                          Cancel
                        </button>
                      </div>
                    ) : (
                      <div className="flex items-center gap-1">
                        <button
                          onClick={() => setRenaming({ id: setlist.id, name: setlist.name })}
                          className="p-2 text-gray-500 hover:text-blue-400 transition-colors"
                          aria-label="Rename setlist"
                          title="Rename"
                        >
                          <FiEdit2 />
                        </button>
                        <button
                          onClick={() => setDeleteConfirm(setlist.id)}
                          className="p-2 text-gray-500 hover:text-red-400 transition-colors"
                          aria-label="Delete setlist"
                          title="Delete"
                        >
                          <FiTrash2 />
                        </button>
                      </div>
                    )}
                  </>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
