import { useState, useEffect } from 'react';
import { Capacitor } from '@capacitor/core';
import { FiX } from 'react-icons/fi';

const BANNER_DISMISSED_KEY = 'jazz-picker-banner-dismissed';

export function WebBanner() {
  // Start as false (show by default), then check localStorage
  const [isDismissed, setIsDismissed] = useState(false);

  useEffect(() => {
    // Only show on web platform (not native iOS app)
    if (Capacitor.isNativePlatform()) {
      setIsDismissed(true);
      return;
    }

    // Check if user previously dismissed
    try {
      const dismissed = localStorage.getItem(BANNER_DISMISSED_KEY);
      if (dismissed === 'true') {
        setIsDismissed(true);
      }
    } catch {
      // localStorage not available, show banner
    }
  }, []);

  const handleDismiss = () => {
    setIsDismissed(true);
    try {
      localStorage.setItem(BANNER_DISMISSED_KEY, 'true');
    } catch {
      // localStorage not available
    }
  };

  // Don't render on native or if dismissed
  if (Capacitor.isNativePlatform() || isDismissed) {
    return null;
  }

  return (
    <div className="bg-blue-600 text-white px-4 py-3 shadow-lg">
      <div className="max-w-4xl mx-auto flex items-center justify-between gap-4">
        <div className="flex-1 text-sm">
          <p className="font-medium">
            📱 Optimized for iPad
          </p>
          <p className="text-blue-100 text-xs mt-0.5">
            Get the native iOS app via TestFlight for the best experience with true fullscreen viewing. Check the About page for details.
          </p>
        </div>
        <button
          onClick={handleDismiss}
          className="flex-shrink-0 p-1 hover:bg-white/20 rounded transition-colors"
          aria-label="Dismiss"
        >
          <FiX className="text-lg" />
        </button>
      </div>
    </div>
  );
}
