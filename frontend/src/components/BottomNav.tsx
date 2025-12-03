import { FiMusic, FiList, FiMoreHorizontal } from 'react-icons/fi';
import { RouletteIcon } from './RouletteIcon';

export type AppContext = 'browse' | 'spin' | 'setlist' | 'menu';

interface BottomNavProps {
  activeContext: AppContext;
  onContextChange: (context: AppContext) => void;
  onSpin?: () => void;
  isSpinning?: boolean;
}

export function BottomNav({ activeContext, onContextChange, onSpin, isSpinning }: BottomNavProps) {
  const handleTabClick = (id: AppContext) => {
    if (id === 'spin' && onSpin) {
      // Always trigger spin when clicking the spin tab
      onSpin();
    } else {
      onContextChange(id);
    }
  };

  const tabs: { id: AppContext; label: string; icon: React.ReactNode }[] = [
    { id: 'browse', label: 'Browse', icon: <FiMusic className="text-xl" /> },
    { id: 'spin', label: 'Spin', icon: <RouletteIcon className="w-5 h-5" spinning={isSpinning} /> },
    { id: 'setlist', label: 'Setlist', icon: <FiList className="text-xl" /> },
    { id: 'menu', label: 'More', icon: <FiMoreHorizontal className="text-xl" /> },
  ];

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-gray-900/95 backdrop-blur-lg border-t border-white/10 pb-[env(safe-area-inset-bottom)] z-40">
      <div className="flex justify-around items-center h-14">
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => handleTabClick(tab.id)}
            className={`flex flex-col items-center justify-center w-full h-full transition-colors ${
              activeContext === tab.id ? 'text-blue-400' : 'text-gray-500 hover:text-gray-300'
            }`}
          >
            {tab.icon}
            <span className="text-[10px] mt-0.5 font-medium">{tab.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
}
