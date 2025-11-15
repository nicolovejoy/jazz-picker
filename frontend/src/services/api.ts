import type { Song } from '@/types/catalog';

const API_BASE = '/api';

export const api = {
  async getSongs(): Promise<Song[]> {
    const response = await fetch(`${API_BASE}/songs`);
    if (!response.ok) {
      throw new Error('Failed to fetch songs');
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

  async getPDF(filename: string): Promise<Blob> {
    const response = await fetch(`/pdf/${encodeURIComponent(filename)}`);
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to load PDF');
    }
    return response.blob();
  },
};
