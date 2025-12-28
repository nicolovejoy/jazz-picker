import {
  FiX,
  FiSearch,
  FiRefreshCw,
  FiList,
  FiUsers,
  FiRadio,
  FiDownload,
} from "react-icons/fi";

declare const __BUILD_TIME__: string;

interface AboutPageProps {
  onClose: () => void;
}

interface FeatureSectionProps {
  icon: React.ReactNode;
  title: string;
  children: React.ReactNode;
}

function FeatureSection({ icon, title, children }: FeatureSectionProps) {
  return (
    <section className="flex gap-4">
      <div className="flex-shrink-0 w-8 h-8 flex items-center justify-center text-blue-400">
        {icon}
      </div>
      <div>
        <h2 className="text-lg font-semibold text-white mb-2">{title}</h2>
        <p className="text-gray-300 leading-relaxed">{children}</p>
      </div>
    </section>
  );
}

export function AboutPage({ onClose }: AboutPageProps) {
  return (
    <div className="fixed inset-0 bg-black/90 z-50 overflow-auto">
      <div className="max-w-2xl mx-auto p-6">
        {/* Header */}
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-2xl font-bold text-white">Jazz Picker</h1>
            <p className="text-gray-400">750+ jazz lead sheets for your gig</p>
          </div>
          <button
            onClick={onClose}
            className="p-2 bg-white/10 hover:bg-white/20 rounded-lg text-white"
            aria-label="Close"
          >
            <FiX className="text-xl" />
          </button>
        </div>

        {/* Content */}
        <div className="space-y-6 border-t border-white/10 pt-6">
          <FeatureSection
            icon={<FiSearch className="text-xl" />}
            title="Browse & Play"
          >
            Search songs by title. Click to open the chart. Click the key button
            to transpose—pick any of 12 keys. Use octave offset (±2) if notes
            land too high or low for your range.
          </FeatureSection>

          <FeatureSection
            icon={<FiRefreshCw className="text-xl" />}
            title="Transposition"
          >
            Set your instrument in Settings. Charts auto-transpose to your
            written key. Trumpet and clarinet see B♭ parts, alto sax sees E♭,
            bass sees bass clef.
          </FeatureSection>

          <FeatureSection
            icon={<FiList className="text-xl" />}
            title="Setlists"
          >
            Organize songs for a gig. Add songs via the menu button while
            viewing a chart. Each setlist item remembers its key and octave.
            Reorder by dragging.
          </FeatureSection>

          <FeatureSection icon={<FiUsers className="text-xl" />} title="Bands">
            Share setlists with bandmates. Create a band in Settings and share
            the join code. Everyone sees the same setlists, synced live.
          </FeatureSection>

          <FeatureSection
            icon={<FiRadio className="text-xl" />}
            title="Groove Sync"
          >
            Lead charts during a gig. Open a setlist and tap "Share Charts."
            Bandmates following along see each song you open, auto-transposed
            for their instrument.
          </FeatureSection>

          <FeatureSection
            icon={<FiDownload className="text-xl" />}
            title="iOS App"
          >
            For offline PDF caching and the best gig experience, use the native
            iOS app. Contact Nico for a TestFlight invite.
          </FeatureSection>
        </div>

        {/* Credits */}
        <div className="mt-8 pt-4 border-t border-white/10">
          <p className="text-sm text-gray-500">
            Lead sheets by Eric, typeset in LilyPond.
          </p>
          <p className="text-sm text-gray-500">
            App by Nico — The Piano House Project
          </p>
          <p className="text-xs text-gray-600 mt-2">
            Built: {__BUILD_TIME__} PST
          </p>
        </div>
      </div>
    </div>
  );
}
