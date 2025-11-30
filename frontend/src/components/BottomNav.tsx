import { FiMusic, FiList, FiSettings } from 'react-icons/fi';

interface BottomNavProps {
  activeTab: 'songs' | 'setlists' | 'settings';
  onTabChange: (tab: 'songs' | 'setlists' | 'settings') => void;
}

export function BottomNav({ activeTab, onTabChange }: BottomNavProps) {
  return (
    <div className="fixed bottom-0 left-0 right-0 bg-gray-900/95 backdrop-blur-lg border-t border-white/10 pb-[env(safe-area-inset-bottom)] z-40">
      <div className="flex justify-around items-center h-16">
        <button
          onClick={() => onTabChange('songs')}
          className={`flex flex-col items-center justify-center w-full h-full transition-colors ${
            activeTab === 'songs' ? 'text-blue-400' : 'text-gray-400 hover:text-gray-200'
          }`}
        >
          <FiMusic className="text-2xl mb-1" />
          <span className="text-xs font-medium">Songs</span>
        </button>

        <button
          onClick={() => onTabChange('setlists')}
          className={`flex flex-col items-center justify-center w-full h-full transition-colors ${
            activeTab === 'setlists' ? 'text-blue-400' : 'text-gray-400 hover:text-gray-200'
          }`}
        >
          <FiList className="text-2xl mb-1" />
          <span className="text-xs font-medium">Setlists</span>
        </button>

        <button
          onClick={() => onTabChange('settings')}
          className={`flex flex-col items-center justify-center w-full h-full transition-colors ${
            activeTab === 'settings' ? 'text-blue-400' : 'text-gray-400 hover:text-gray-200'
          }`}
        >
          <FiSettings className="text-2xl mb-1" />
          <span className="text-xs font-medium">Settings</span>
        </button>
      </div>
    </div>
  );
}
