import { FiX } from 'react-icons/fi';

interface AboutPageProps {
  onClose: () => void;
}

export function AboutPage({ onClose }: AboutPageProps) {
  return (
    <div className="fixed inset-0 bg-black/90 z-50 overflow-auto">
      <div className="max-w-2xl mx-auto p-6">
        {/* Header */}
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-2xl font-bold text-white">About Jazz Picker</h1>
          <button
            onClick={onClose}
            className="p-2 bg-white/10 hover:bg-white/20 rounded-lg text-white"
            aria-label="Close"
          >
            <FiX className="text-xl" />
          </button>
        </div>

        {/* Content */}
        <div className="space-y-8 text-gray-300">
          {/* What is this */}
          <section>
            <h2 className="text-lg font-semibold text-white mb-3">What is this?</h2>
            <p className="leading-relaxed">
              Jazz Picker is an iPad-first web app for browsing and viewing jazz lead sheets
              at the gig. It provides access to Eric's collection of over 735 jazz standards,
              dynamically generated in any of the 12 concert keys for your specific instrument
              and clef.
            </p>
          </section>

          {/* Features */}
          <section>
            <h2 className="text-lg font-semibold text-white mb-3">Features</h2>
            <ul className="space-y-2 list-disc list-inside">
              <li>Browse 735+ jazz standards</li>
              <li>Generate charts in any of the 12 concert keys on demand</li>
              <li>Multi-instrument support (Piano, Trumpet, Alto Sax, Bass, and more)</li>
              <li>Search by song title</li>
              <li>Spin the wheel for a random song</li>
              <li>Create setlists for gigs with swipe navigation</li>
              <li>iPad-optimized PDF viewer with landscape side-by-side mode</li>
            </ul>
          </section>

          {/* Native iOS App */}
          <section>
            <h2 className="text-lg font-semibold text-white mb-3">Native iOS App (Recommended)</h2>
            <p className="mb-4 leading-relaxed">
              For the best experience with true fullscreen PDF viewing and hidden status bars,
              join our TestFlight beta for the native iOS app.
            </p>

            <div className="bg-blue-500/10 border border-blue-500/30 rounded-lg p-4">
              <p className="text-blue-300 mb-2 font-medium">🚀 Join TestFlight Beta</p>
              <p className="text-sm text-gray-300">
                Contact Nico for a TestFlight invite to get the native app with enhanced
                iPad features and offline support.
              </p>
            </div>
          </section>

          {/* Install as PWA */}
          <section>
            <h2 className="text-lg font-semibold text-white mb-3">Add to Home Screen (Web)</h2>
            <p className="mb-4 leading-relaxed">
              You can also use this web version as a progressive web app by adding it
              to your home screen.
            </p>

            <div className="bg-white/5 border border-white/10 rounded-lg p-4 space-y-4">
              <div className="flex gap-3">
                <span className="flex-shrink-0 w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center text-white text-sm font-medium">1</span>
                <p>Open <strong className="text-white">jazzpicker.pianohouseproject.org</strong> in Safari</p>
              </div>

              <div className="flex gap-3">
                <span className="flex-shrink-0 w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center text-white text-sm font-medium">2</span>
                <p>Tap the <strong className="text-white">Share button</strong> (square with arrow pointing up)</p>
              </div>

              <div className="flex gap-3">
                <span className="flex-shrink-0 w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center text-white text-sm font-medium">3</span>
                <p>Scroll down and tap <strong className="text-white">"Add to Home Screen"</strong></p>
              </div>

              <div className="flex gap-3">
                <span className="flex-shrink-0 w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center text-white text-sm font-medium">4</span>
                <p>Tap <strong className="text-white">"Add"</strong> in the top right</p>
              </div>
            </div>

            <p className="mt-4 text-sm text-gray-400">
              Note: This only works in Safari. Chrome and other browsers don't support
              adding web apps to the home screen on iOS.
            </p>
          </section>

          {/* Credits */}
          <section>
            <h2 className="text-lg font-semibold text-white mb-3">Credits</h2>
            <p className="leading-relaxed">
              Lead sheets by <strong className="text-white">Eric Stern</strong>,
              typeset in LilyPond. App by <strong className="text-white">Nico</strong>.
            </p>
          </section>

          {/* Version */}
          <section className="pt-4 border-t border-white/10">
            <p className="text-sm text-gray-500">
              Jazz Picker v2.1 — The Piano House Project
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
