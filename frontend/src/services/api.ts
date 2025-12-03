import { Capacitor } from '@capacitor/core';
import type { SongListResponse, SongSummary, Transposition, Clef } from '@/types/catalog';
import type { CropBounds } from '@/types/pdf';

// Native app needs full URL. Web uses relative URLs (Vite proxy in dev, same origin in prod).
const BACKEND_URL = Capacitor.isNativePlatform()
  ? 'https://jazz-picker.fly.dev'
  : (import.meta.env.VITE_BACKEND_URL || '');
const API_BASE = `${BACKEND_URL}/api`;

export interface GenerateResponse {
  url: string;
  cached: boolean;
  generation_time_ms: number;
  crop?: CropBounds;
}

export interface CachedKeysResponse {
  default_key: string;
  cached_concert_keys: string[];
}

export interface CatalogResponse {
  songs: SongSummary[];
  total: number;
}

export const api = {
  async getSongsV2(
    limit = 50,
    offset = 0,
    query = ''
  ): Promise<SongListResponse> {
    const params = new URLSearchParams({
      limit: limit.toString(),
      offset: offset.toString(),
      q: query,
    });
    const response = await fetch(`${API_BASE}/v2/songs?${params}`);
    if (!response.ok) throw new Error('Failed to fetch songs');
    return response.json();
  },

  async generatePDF(
    song: string,
    concertKey: string,
    transposition: Transposition,
    clef: Clef,
    instrumentLabel?: string
  ): Promise<GenerateResponse> {
    const body: Record<string, string> = {
      song,
      concert_key: concertKey,
      transposition,
      clef,
    };
    if (instrumentLabel) {
      body.instrument_label = instrumentLabel;
    }

    const response = await fetch(`${API_BASE}/v2/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: 'Generation failed' }));
      throw new Error(error.error || 'Failed to generate PDF');
    }

    return response.json();
  },

  async getCachedKeys(
    songTitle: string,
    transposition: Transposition,
    clef: Clef
  ): Promise<CachedKeysResponse> {
    const params = new URLSearchParams({
      transposition,
      clef,
    });
    const response = await fetch(
      `${API_BASE}/v2/songs/${encodeURIComponent(songTitle)}/cached?${params}`
    );
    if (!response.ok) {
      throw new Error('Failed to fetch cached keys');
    }
    return response.json();
  },

  async getCatalog(): Promise<CatalogResponse> {
    const response = await fetch(`${API_BASE}/v2/catalog`);
    if (!response.ok) throw new Error('Failed to fetch catalog');
    return response.json();
  },
};
