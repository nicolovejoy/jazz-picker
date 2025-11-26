import type { Song, SongListResponse, SongDetail } from '@/types/catalog';

// In production, use the Fly.io backend directly. In dev, use Vite's proxy.
const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || '';
const API_BASE = `${BACKEND_URL}/api`;

export const api = {
  async getSongs(): Promise<Song[]> {
    const response = await fetch(`${API_BASE}/songs`);
    if (!response.ok) {
      throw new Error('Failed to fetch songs');
    }
    return response.json();
  },

  async getSongsV2(
    limit = 50, 
    offset = 0, 
    query = '', 
    instrument = 'All', 
    singerRange = 'All'
  ): Promise<SongListResponse> {
    const params = new URLSearchParams({
      limit: limit.toString(),
      offset: offset.toString(),
      q: query,
      instrument,
      range: singerRange,
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

  async searchSongs(query: string): Promise<Song[]> {
    const response = await fetch(`${API_BASE}/songs/search?q=${encodeURIComponent(query)}`);
    if (!response.ok) {
      throw new Error('Failed to search songs');
    }
    return response.json();
  },

  async getPDF(filename: string): Promise<string> {
    console.log('[API] Fetching PDF:', filename);
    const url = `${BACKEND_URL}/pdf/${encodeURIComponent(filename)}`;
    console.log('[API] URL:', url);

    const response = await fetch(url);
    console.log('[API] Response status:', response.status, response.statusText);

    if (!response.ok) {
      let errorMsg = 'Failed to load PDF';
      try {
        const error = await response.json();
        errorMsg = error.error || errorMsg;
        console.error('[API] Error response:', error);
      } catch (e) {
        console.error('[API] Could not parse error response');
      }
      throw new Error(errorMsg);
    }

    // Check if response is JSON (S3 presigned URL) or PDF blob
    const contentType = response.headers.get('content-type');

    if (contentType?.includes('application/json')) {
      // S3 presigned URL response
      const data = await response.json();
      console.log('[API] S3 presigned URL received:', data);
      return data.url;
    } else {
      // Direct PDF blob (fallback mode)
      const blob = await response.blob();
      console.log('[API] Blob received:', blob.type, blob.size, 'bytes');
      // Convert blob to object URL
      return URL.createObjectURL(blob);
    }
  },
};
