export interface Variation {
  filename: string;
  filepath: string;
  title: string;
  key_and_variation: string;
  pdf_path: string;
  display_name: string;
  instrument: string;
  key: string;
  clef: string;
  core_file: string;
  variation_type: string;
}

// API v2 Types
export interface SongSummary {
  title: string;
  variation_count: number;
  available_instruments: string[];
}

export interface SongDetailVariation {
  id: string;
  display_name: string;
  key: string;
  instrument: string;
  variation_type: string;
  filename: string;
  songTitle?: string; // Added client-side for generation
}

export interface SongDetail {
  title: string;
  variations: SongDetailVariation[];
}

export interface SongListResponse {
  songs: SongSummary[];
  total: number;
  limit: number;
  offset: number;
}

// Filter types
export type InstrumentType = 'C' | 'Bb' | 'Eb' | 'Bass' | 'All';

// Helper to map variation_type to instrument categories
export function getInstrumentCategory(variationType: string): InstrumentType | null {
  if (variationType.includes('Standard')) return 'C';
  if (variationType.includes('Bb Instrument')) return 'Bb';
  if (variationType.includes('Eb Instrument')) return 'Eb';
  if (variationType.includes('Bass')) return 'Bass';
  // Alto Voice and Baritone Voice are typically C instruments (concert pitch)
  if (variationType.includes('Alto Voice') || variationType.includes('Baritone Voice')) return 'C';
  return null;
}
