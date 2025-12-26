import { FiMusic } from 'react-icons/fi';
import type { GrooveSyncSession } from '@/services/grooveSyncService';

interface GrooveSyncModalProps {
  session: GrooveSyncSession;
  onJoin: () => void;
  onDismiss: () => void;
  onDismissSession: () => void;
}

export function GrooveSyncModal({ session, onJoin, onDismiss, onDismissSession }: GrooveSyncModalProps) {
  return (
    <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4">
      <div className="bg-gray-800 rounded-xl max-w-sm w-full p-6 shadow-2xl">
        <div className="flex flex-col items-center">
          <div className="w-16 h-16 rounded-full bg-blue-500/20 flex items-center justify-center mb-4">
            <FiMusic className="text-blue-400 text-3xl" />
          </div>

          <h2 className="text-xl font-semibold mb-2 text-center">
            {session.leaderName} is sharing charts
          </h2>

          <p className="text-gray-400 text-center mb-6">
            Follow along to see the same charts, transposed for your instrument.
          </p>

          <div className="flex gap-3 w-full">
            <button
              onClick={onDismiss}
              className="flex-1 px-4 py-3 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors"
            >
              Not now
            </button>
            <button
              onClick={onJoin}
              className="flex-1 px-4 py-3 bg-blue-600 hover:bg-blue-500 rounded-lg transition-colors font-medium"
            >
              Follow
            </button>
          </div>

          <button
            onClick={onDismissSession}
            className="mt-4 text-gray-500 hover:text-gray-400 text-sm transition-colors"
          >
            Don't ask again for this session
          </button>
        </div>
      </div>
    </div>
  );
}
