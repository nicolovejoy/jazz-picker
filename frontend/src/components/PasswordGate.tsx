import { useState } from 'react';

interface PasswordGateProps {
  onAuthenticated: () => void;
}

const CORRECT_PASSWORD = 'vashonista!';

export function PasswordGate({ onAuthenticated }: PasswordGateProps) {
  const [password, setPassword] = useState('');
  const [error, setError] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (password === CORRECT_PASSWORD) {
      onAuthenticated();
    } else {
      setError(true);
      setPassword('');
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 flex items-center justify-center p-6">
      <div className="max-w-sm w-full">
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-blue-400 mb-2">
            Jazz Picker
          </h1>
          <p className="text-gray-400">
            Eric's Lead Sheet Collection
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <input
              type="password"
              value={password}
              onChange={(e) => {
                setPassword(e.target.value);
                setError(false);
              }}
              placeholder="Enter password"
              autoFocus
              className={`w-full px-4 py-3 bg-white/10 border rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-400 ${
                error ? 'border-red-500' : 'border-white/20'
              }`}
            />
            {error && (
              <p className="mt-2 text-sm text-red-400">
                Incorrect password
              </p>
            )}
          </div>

          <button
            type="submit"
            className="w-full py-3 bg-blue-600 hover:bg-blue-500 text-white font-medium rounded-lg transition-colors"
          >
            Enter
          </button>
        </form>
      </div>
    </div>
  );
}
