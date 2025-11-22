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

export interface Song {
  title: string;
  core_files: string[];
  variations: Variation[];
}

// API v2 Types
export interface SongSummary {
  title: string;
  variation_count: number;
  available_instruments: string[];
  available_ranges: string[];
}

export interface SongDetailVariation {
  id: string;
  display_name: string;
  key: string;
  instrument: string;
  variation_type: string;
  filename: string;
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

export interface CatalogMetadata {
  total_files: number;
  total_songs: number;
  generated: string;
}

export interface Catalog {
  metadata: CatalogMetadata;
  songs: Record<string, Song>;
}

// Filter types
export type InstrumentType = 'C' | 'Bb' | 'Eb' | 'Bass' | 'All';
export type SingerRangeType = 'Alto/Mezzo/Soprano' | 'Baritone/Tenor/Bass' | 'Standard' | 'All';

export interface UserPreferences {
  instrument: InstrumentType;
  singerRange: SingerRangeType;
}

// Helper to map variation_type to instrument categories
export function getInstrumentCategory(variationType: string): InstrumentType | null {
  if (variationType.includes('Standard (Concert)')) return 'C';
  if (variationType.includes('Bb Instrument')) return 'Bb';
  if (variationType.includes('Eb Instrument')) return 'Eb';
  if (variationType.includes('Bass')) return 'Bass';
  // Alto Voice and Baritone Voice are typically C instruments (concert pitch)
  if (variationType.includes('Alto Voice') || variationType.includes('Baritone Voice')) return 'C';
  return null;
}

// Helper to map variation_type to singer range categories
export function getSingerRangeCategory(variationType: string): SingerRangeType | null {
  if (variationType.includes('Alto Voice')) return 'Alto/Mezzo/Soprano';
  if (variationType.includes('Baritone Voice')) return 'Baritone/Tenor/Bass';
  if (variationType.includes('Standard')) return 'Standard';
  return null;
}
