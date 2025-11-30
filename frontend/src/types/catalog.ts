// API v2 Types
export interface SongSummary {
  title: string;
  default_key: string;
}

export interface SongListResponse {
  songs: SongSummary[];
  total: number;
  limit: number;
  offset: number;
}

// Transposition types
export type Transposition = 'C' | 'Bb' | 'Eb';
export type Clef = 'treble' | 'bass';

// Instrument definition
export interface Instrument {
  id: string;
  label: string;
  transposition: Transposition;
  clef: Clef;
}

// Fixed instrument list
export const INSTRUMENTS: Instrument[] = [
  { id: 'piano',       label: 'Piano',       transposition: 'C',  clef: 'treble' },
  { id: 'guitar',      label: 'Guitar',      transposition: 'C',  clef: 'treble' },
  { id: 'trumpet',     label: 'Trumpet',     transposition: 'Bb', clef: 'treble' },
  { id: 'clarinet',    label: 'Clarinet',    transposition: 'Bb', clef: 'treble' },
  { id: 'tenor-sax',   label: 'Tenor Sax',   transposition: 'Bb', clef: 'treble' },
  { id: 'soprano-sax', label: 'Soprano Sax', transposition: 'Bb', clef: 'treble' },
  { id: 'alto-sax',    label: 'Alto Sax',    transposition: 'Eb', clef: 'treble' },
  { id: 'bari-sax',    label: 'Bari Sax',    transposition: 'Eb', clef: 'treble' },
  { id: 'bass',        label: 'Bass',        transposition: 'C',  clef: 'bass' },
  { id: 'trombone',    label: 'Trombone',    transposition: 'C',  clef: 'bass' },
];

// Helper to get instrument by ID
export function getInstrumentById(id: string): Instrument | undefined {
  return INSTRUMENTS.find(i => i.id === id);
}

// Key constants for transposition math
const KEYS = ['c', 'cs', 'd', 'ef', 'e', 'f', 'fs', 'g', 'af', 'a', 'bf', 'b'];
const KEY_DISPLAY: Record<string, string> = {
  'c': 'C', 'cs': 'C♯', 'df': 'D♭', 'd': 'D', 'ds': 'D♯', 'ef': 'E♭',
  'e': 'E', 'f': 'F', 'fs': 'F♯', 'gf': 'G♭', 'g': 'G', 'gs': 'G♯',
  'af': 'A♭', 'a': 'A', 'as': 'A♯', 'bf': 'B♭', 'b': 'B'
};

// Transposition intervals (in semitones up from concert pitch)
const TRANSPOSITION_INTERVALS: Record<Transposition, number> = {
  'C': 0,   // Concert pitch
  'Bb': 2,  // Up a major 2nd (written C = concert Bb)
  'Eb': 9,  // Up a major 6th (written C = concert Eb)
};

/**
 * Convert concert key to written key for a given transposition.
 * Example: concertToWritten('ef', 'Bb') => 'f' (Eb concert = F written for Bb instruments)
 */
export function concertToWritten(concertKey: string, transposition: Transposition): string {
  // Normalize key (handle enharmonics)
  let normalizedKey = concertKey.toLowerCase().replace(/s$/, 's').replace(/f$/, 'f');
  // Handle df -> cs, gf -> fs, etc for lookup
  if (normalizedKey === 'df') normalizedKey = 'cs';
  if (normalizedKey === 'gf') normalizedKey = 'fs';
  if (normalizedKey === 'ds') normalizedKey = 'ef';
  if (normalizedKey === 'as') normalizedKey = 'bf';
  if (normalizedKey === 'gs') normalizedKey = 'af';

  const concertIndex = KEYS.indexOf(normalizedKey);
  if (concertIndex === -1) return concertKey; // Unknown key, return as-is

  const interval = TRANSPOSITION_INTERVALS[transposition];
  const writtenIndex = (concertIndex + interval) % 12;

  return KEYS[writtenIndex];
}

/**
 * Format a key for display (e.g., 'ef' -> 'E♭')
 */
export function formatKey(key: string): string {
  const normalized = key.toLowerCase();
  return KEY_DISPLAY[normalized] || key.toUpperCase();
}

/**
 * Format key display based on instrument.
 * C instruments: just the concert key
 * Transposing instruments: "F for Trumpet (Concert Eb)"
 */
export function formatKeyForInstrument(
  concertKey: string,
  instrument: Instrument
): string {
  const concertDisplay = formatKey(concertKey);

  if (instrument.transposition === 'C') {
    return concertDisplay;
  }

  const writtenKey = concertToWritten(concertKey, instrument.transposition);
  const writtenDisplay = formatKey(writtenKey);

  return `${writtenDisplay} for ${instrument.label} (Concert ${concertDisplay})`;
}
