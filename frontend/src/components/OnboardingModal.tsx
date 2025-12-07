import { useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useUserProfile } from '@/contexts/UserProfileContext';
import { INSTRUMENTS, type Instrument } from '@/types/catalog';

const instrumentGroups = [
  {
    label: 'Concert Pitch (C)',
    instruments: INSTRUMENTS.filter(i => i.transposition === 'C' && i.clef === 'treble'),
  },
  {
    label: 'Bb Instruments',
    instruments: INSTRUMENTS.filter(i => i.transposition === 'Bb'),
  },
  {
    label: 'Eb Instruments',
    instruments: INSTRUMENTS.filter(i => i.transposition === 'Eb'),
  },
  {
    label: 'Bass Clef',
    instruments: INSTRUMENTS.filter(i => i.clef === 'bass'),
  },
];

export function OnboardingModal() {
  const { user } = useAuth();
  const { createProfile } = useUserProfile();
  const [displayName, setDisplayName] = useState(user?.displayName || '');
  const [selectedInstrument, setSelectedInstrument] = useState<Instrument | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const canSubmit = displayName.trim().length > 0 && selectedInstrument !== null && !saving;

  const handleSubmit = async () => {
    if (!canSubmit || !selectedInstrument) return;

    setSaving(true);
    setError(null);

    try {
      await createProfile({
        instrument: selectedInstrument.id,
        displayName: displayName.trim(),
      });
    } catch (err) {
      console.error('Failed to create profile:', err);
      setError('Failed to save profile. Please try again.');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 flex items-center justify-center p-6 z-50 overflow-y-auto">
      <div className="max-w-lg w-full py-8">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-white mb-2">Complete Your Profile</h1>
          <p className="text-gray-400">Set up your preferences to get started</p>
        </div>

        <div className="space-y-6">
          {/* Display Name */}
          <div>
            <label htmlFor="displayName" className="block text-sm font-medium text-gray-300 mb-2">
              Display Name
            </label>
            <input
              id="displayName"
              type="text"
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              placeholder="Your name"
              className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-400 focus:ring-1 focus:ring-blue-400"
            />
          </div>

          {/* Instrument Selection */}
          <div>
            <p className="text-sm font-medium text-gray-300 mb-3">
              What instrument do you play?
            </p>

            <div className="space-y-3">
              {instrumentGroups.map((group) => (
                <div key={group.label} className="bg-white/5 rounded-lg p-3 border border-white/10">
                  <h3 className="text-xs font-medium text-gray-400 uppercase tracking-wide mb-2">
                    {group.label}
                  </h3>
                  <div className="flex flex-wrap gap-2">
                    {group.instruments.map((inst) => (
                      <button
                        key={inst.id}
                        onClick={() => setSelectedInstrument(inst)}
                        className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-all ${
                          selectedInstrument?.id === inst.id
                            ? 'bg-blue-500 text-white border border-blue-400'
                            : 'bg-white/10 text-white border border-white/20 hover:bg-white/20'
                        }`}
                      >
                        {inst.label}
                      </button>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {error && (
            <p className="text-red-400 text-sm text-center">{error}</p>
          )}

          {/* Continue Button */}
          <button
            onClick={handleSubmit}
            disabled={!canSubmit}
            className={`w-full py-3 rounded-lg font-medium transition-all ${
              canSubmit
                ? 'bg-blue-500 hover:bg-blue-600 text-white'
                : 'bg-gray-700 text-gray-500 cursor-not-allowed'
            }`}
          >
            {saving ? 'Saving...' : 'Continue'}
          </button>
        </div>
      </div>
    </div>
  );
}
