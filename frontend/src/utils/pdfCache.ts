import type { Transposition, Clef } from '@/types/catalog';

/**
 * Convert a song title to a URL-safe slug
 * Example: "502 Blues" -> "502-blues"
 */
function slugify(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')  // Replace non-alphanumeric with hyphens
    .replace(/^-+|-+$/g, '');      // Trim leading/trailing hyphens
}

/**
 * Build a unique cache key for a PDF
 * Format: {song-slug}-{concert-key}-{transposition}-{clef}
 * Example: "blue-bossa-cm-Bb-treble"
 */
export function buildCacheKey(
  songTitle: string,
  concertKey: string,
  transposition: Transposition,
  clef: Clef
): string {
  const slug = slugify(songTitle);
  const keyLower = concertKey.toLowerCase();
  return `${slug}-${keyLower}-${transposition}-${clef}`;
}

/**
 * Format bytes to human-readable string
 * Example: 1048576 -> "1.0 MB"
 */
export function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B';

  const units = ['B', 'KB', 'MB', 'GB'];
  const k = 1024;
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return `${(bytes / Math.pow(k, i)).toFixed(1)} ${units[i]}`;
}
