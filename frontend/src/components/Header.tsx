import { useEffect, useRef } from 'react';
import { FiSearch, FiX } from 'react-icons/fi';

declare const __BUILD_TIME__: string;
const BUILD_TIME = __BUILD_TIME__;

interface HeaderProps {
  searchQuery: string;
  onSearch: (query: string) => void;
  onEnterPress: () => void;
}

export function Header({
  searchQuery,
  onSearch,
  onEnterPress,
}: HeaderProps) {
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      onEnterPress();
    }
  };

  return (
    <header className="fixed top-0 left-0 right-0 bg-gray-900/95 backdrop-blur-lg border-b border-white/10 pt-[env(safe-area-inset-top)] z-40">
      <div className="flex items-center justify-between h-14 px-4">
        <span className="text-2xl font-bold text-blue-400">Jazz Picker</span>

        <div className="relative w-[55%]">
          <FiSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 text-sm pointer-events-none" />
          <input
            ref={inputRef}
            type="text"
            value={searchQuery}
            onChange={(e) => onSearch(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Search songs..."
            className="w-full pl-9 pr-9 py-2 text-sm bg-white/5 border border-white/10 rounded text-white placeholder-gray-500 focus:outline-none focus:border-blue-400/50 transition-colors"
          />
          {searchQuery && (
            <button
              onClick={() => onSearch('')}
              className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-500 hover:text-white transition-colors p-1"
              aria-label="Clear search"
            >
              <FiX className="text-sm" />
            </button>
          )}
        </div>

        <span className="text-xs text-gray-400">v{BUILD_TIME}</span>
      </div>
    </header>
  );
}
