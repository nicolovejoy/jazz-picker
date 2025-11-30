import { useState } from 'react';
import { supabase } from '@/lib/supabase';

type AuthView = 'sign_in' | 'sign_up' | 'forgot_password' | 'check_email';

export function AuthGate() {
  const [view, setView] = useState<AuthView>('sign_in');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      setError(error.message);
    }
    setLoading(false);
  };

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const { error } = await supabase.auth.signUp({
      email,
      password,
    });

    if (error) {
      setError(error.message);
    } else {
      setView('check_email');
    }
    setLoading(false);
  };

  const handleForgotPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`,
    });

    if (error) {
      setError(error.message);
    } else {
      setMessage('Check your email for a password reset link');
    }
    setLoading(false);
  };

  const renderForm = () => {
    if (view === 'check_email') {
      return (
        <div className="text-center">
          <h2 className="text-xl font-semibold text-white mb-4">Check your email</h2>
          <p className="text-gray-400 mb-6">
            We sent a confirmation link to <span className="text-white">{email}</span>
          </p>
          <button
            onClick={() => setView('sign_in')}
            className="text-blue-400 hover:text-blue-300"
          >
            Back to sign in
          </button>
        </div>
      );
    }

    if (view === 'forgot_password') {
      return (
        <form onSubmit={handleForgotPassword} className="space-y-4">
          <div>
            <label className="block text-sm text-gray-400 mb-1">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-400"
              placeholder="you@example.com"
            />
          </div>

          {error && <p className="text-red-400 text-sm">{error}</p>}
          {message && <p className="text-green-400 text-sm">{message}</p>}

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 bg-blue-600 hover:bg-blue-500 disabled:bg-blue-600/50 text-white font-medium rounded-lg transition-colors"
          >
            {loading ? 'Sending...' : 'Send reset link'}
          </button>

          <button
            type="button"
            onClick={() => {
              setView('sign_in');
              setError(null);
              setMessage(null);
            }}
            className="w-full text-gray-400 hover:text-white text-sm"
          >
            Back to sign in
          </button>
        </form>
      );
    }

    return (
      <form onSubmit={view === 'sign_in' ? handleSignIn : handleSignUp} className="space-y-4">
        <div>
          <label className="block text-sm text-gray-400 mb-1">Email</label>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            autoFocus
            className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-400"
            placeholder="you@example.com"
          />
        </div>

        <div>
          <label className="block text-sm text-gray-400 mb-1">Password</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            minLength={6}
            className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-400"
            placeholder="••••••••"
          />
        </div>

        {error && <p className="text-red-400 text-sm">{error}</p>}

        <button
          type="submit"
          disabled={loading}
          className="w-full py-3 bg-blue-600 hover:bg-blue-500 disabled:bg-blue-600/50 text-white font-medium rounded-lg transition-colors"
        >
          {loading ? 'Loading...' : view === 'sign_in' ? 'Sign in' : 'Sign up'}
        </button>

        {view === 'sign_in' && (
          <button
            type="button"
            onClick={() => {
              setView('forgot_password');
              setError(null);
            }}
            className="w-full text-gray-400 hover:text-white text-sm"
          >
            Forgot password?
          </button>
        )}

        <div className="text-center text-gray-400 text-sm">
          {view === 'sign_in' ? (
            <>
              Don't have an account?{' '}
              <button
                type="button"
                onClick={() => {
                  setView('sign_up');
                  setError(null);
                }}
                className="text-blue-400 hover:text-blue-300"
              >
                Sign up
              </button>
            </>
          ) : (
            <>
              Already have an account?{' '}
              <button
                type="button"
                onClick={() => {
                  setView('sign_in');
                  setError(null);
                }}
                className="text-blue-400 hover:text-blue-300"
              >
                Sign in
              </button>
            </>
          )}
        </div>
      </form>
    );
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

        <div className="bg-white/5 border border-white/10 rounded-lg p-6">
          {renderForm()}
        </div>
      </div>
    </div>
  );
}
