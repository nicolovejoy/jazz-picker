import type { SongListResponse, SongSummary, Transposition, Clef } from '@/types/catalog';
import type { CropBounds } from '@/types/pdf';

// Web uses relative URLs (Vite proxy in dev, same origin in prod)
const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || '';
const API_BASE = `${BACKEND_URL}/api`;

// Normalize key format from catalog (am, bb) to LilyPond notation (a, bf)
// TODO: Remove once catalog is rebuilt with correct format
function normalizeKey(key: string): string {
  let k = key.toLowerCase().replace(/m$/, ''); // Strip minor 'm' suffix
  k = k.replace('#', 's'); // Sharp: # -> s
  if (k.length === 2 && k[1] === 'b' && k[0] !== 'b') {
    k = k[0] + 'f'; // Flat: xb -> xf (but not 'b' alone)
  }
  return k;
}

export interface GenerateResponse {
  url: string;
  cached: boolean;
  generation_time_ms: number;
  crop?: CropBounds;
  octave_offset?: number;
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
    instrumentLabel?: string,
    octaveOffset?: number
  ): Promise<GenerateResponse> {
    const body: Record<string, string | number> = {
      song,
      concert_key: normalizeKey(concertKey),
      transposition,
      clef,
    };
    if (instrumentLabel) {
      body.instrument_label = instrumentLabel;
    }
    if (octaveOffset !== undefined && octaveOffset !== 0) {
      body.octave_offset = octaveOffset;
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
