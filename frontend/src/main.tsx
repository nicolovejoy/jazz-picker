import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import './index.css';
import App from './App.tsx';
import { api } from './services/api';
import { AuthProvider } from './contexts/AuthContext';
import { UserProfileProvider } from './contexts/UserProfileContext';
import { GroupsProvider } from './contexts/GroupsContext';
import { SetlistProvider } from './contexts/SetlistContext';
import { GrooveSyncProvider } from './contexts/GrooveSyncContext';

// Polyfill for URL.parse() - needed for Safari 17 and older browsers.
// pdfjs-dist 5.x uses URL.parse() which was only added in Safari 18 (Sept 2024).
// If this causes issues, we could instead downgrade to react-pdf 9.x / pdfjs-dist 4.x.
if (typeof URL.parse !== 'function') {
  (URL as typeof URL & { parse: typeof URL.parse }).parse = function (
    url: string | URL,
    base?: string | URL
  ): URL | null {
    try {
      return new URL(url, base);
    } catch {
      return null;
    }
  };
}

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

// Prefetch songs immediately on app load
queryClient.prefetchQuery({
  queryKey: ['songs', 50, 0, ''],
  queryFn: () => api.getSongsV2(50, 0, ''),
});

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AuthProvider>
      <UserProfileProvider>
        <GroupsProvider>
          <SetlistProvider>
            <GrooveSyncProvider>
              <QueryClientProvider client={queryClient}>
                <App />
              </QueryClientProvider>
            </GrooveSyncProvider>
          </SetlistProvider>
        </GroupsProvider>
      </UserProfileProvider>
    </AuthProvider>
  </StrictMode>
);
