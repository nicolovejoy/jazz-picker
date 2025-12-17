import { useState, useEffect } from 'react';
import { useGroups } from '@/contexts/GroupsContext';
import { getGroupByCode } from '@/services/groupService';
import type { Group } from '@/types/group';

interface JoinBandModalProps {
  code: string;
  onClose: () => void;
  onJoined: () => void;
}

export function JoinBandModal({ code, onClose, onJoined }: JoinBandModalProps) {
  const { joinGroup } = useGroups();
  const [band, setBand] = useState<Group | null>(null);
  const [loading, setLoading] = useState(true);
  const [joining, setJoining] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [joined, setJoined] = useState(false);

  useEffect(() => {
    async function lookupBand() {
      try {
        const found = await getGroupByCode(code);
        setBand(found);
      } catch (err) {
        setError('Failed to look up band');
      } finally {
        setLoading(false);
      }
    }
    lookupBand();
  }, [code]);

  const handleJoin = async () => {
    setJoining(true);
    setError(null);
    try {
      await joinGroup(code);
      setJoined(true);
      // Auto-close after success
      setTimeout(() => {
        onJoined();
      }, 1500);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to join band');
      setJoining(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4">
      <div className="bg-gray-800 rounded-xl max-w-sm w-full p-6 shadow-2xl">
        {loading ? (
          <div className="flex flex-col items-center py-8">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-400"></div>
            <p className="mt-4 text-gray-400">Looking up band...</p>
          </div>
        ) : joined ? (
          <div className="flex flex-col items-center py-8">
            <div className="text-green-400 text-5xl mb-4">&#10003;</div>
            <p className="text-xl font-semibold">Joined {band?.name}</p>
          </div>
        ) : band ? (
          <div className="flex flex-col items-center">
            <div className="text-blue-400 text-5xl mb-4">&#128101;</div>
            <h2 className="text-xl font-semibold mb-2">Join {band.name}?</h2>
            <p className="text-gray-400 text-center mb-6">
              You'll see setlists shared by this band.
            </p>

            {error && (
              <p className="text-red-400 text-sm mb-4 text-center">{error}</p>
            )}

            <div className="flex gap-3 w-full">
              <button
                onClick={onClose}
                disabled={joining}
                className="flex-1 px-4 py-3 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                onClick={handleJoin}
                disabled={joining}
                className="flex-1 px-4 py-3 bg-blue-600 hover:bg-blue-500 rounded-lg transition-colors disabled:opacity-50"
              >
                {joining ? 'Joining...' : 'Join Band'}
              </button>
            </div>
          </div>
        ) : (
          <div className="flex flex-col items-center py-8">
            <div className="text-orange-400 text-5xl mb-4">&#9888;</div>
            <h2 className="text-xl font-semibold mb-2">Band not found</h2>
            <p className="text-gray-400 text-center mb-6">
              The invite link may be invalid or expired.
            </p>
            <button
              onClick={onClose}
              className="px-6 py-3 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors"
            >
              Close
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
