import type { SongListResponse, SongDetail } from '@/types/catalog';

// In production, use the Fly.io backend directly. In dev, use Vite's proxy.
const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || '';
const API_BASE = `${BACKEND_URL}/api`;

export interface GenerateResponse {
  url: string;
  cached: boolean;
  generation_time_ms: number;
}

export interface CachedKey {
  key: string;
  clef: string;
}

export interface CachedKeysResponse {
  default_key: string;
  default_clef: string;
  cached_keys: CachedKey[];
}

export const api = {
  async getSongsV2(
    limit = 50,
    offset = 0,
    query = '',
    instrument = 'All'
  ): Promise<SongListResponse> {
    const params = new URLSearchParams({
      limit: limit.toString(),
      offset: offset.toString(),
      q: query,
      instrument,
    });
    const response = await fetch(`${API_BASE}/v2/songs?${params}`);
    if (!response.ok) throw new Error('Failed to fetch songs');
    return response.json();
  },

  async getSongV2(title: string): Promise<SongDetail> {
    const response = await fetch(`${API_BASE}/v2/songs/${encodeURIComponent(title)}`);
    if (!response.ok) {
      throw new Error('Failed to fetch song details');
    }
    return response.json();
  },

  async generatePDF(
    song: string,
    key: string,
    clef: 'treble' | 'bass' = 'treble'
  ): Promise<GenerateResponse> {
    const response = await fetch(`${API_BASE}/v2/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ song, key, clef }),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: 'Generation failed' }));
      throw new Error(error.error || 'Failed to generate PDF');
    }

    return response.json();
  },

  async getCachedKeys(songTitle: string): Promise<CachedKeysResponse> {
    const response = await fetch(
      `${API_BASE}/v2/songs/${encodeURIComponent(songTitle)}/cached`
    );
    if (!response.ok) {
      throw new Error('Failed to fetch cached keys');
    }
    return response.json();
  },
};
