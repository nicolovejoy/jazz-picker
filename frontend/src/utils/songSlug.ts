import type { SongSummary } from '@/types/catalog';

/**
 * Convert a song title to a URL-safe slug.
 * "All The Things You Are" → "all-the-things-you-are"
 * "Body and Soul" → "body-and-soul"
 * "I've Got Rhythm" → "ive-got-rhythm"
 */
export function toSongSlug(title: string): string {
  return title
    .toLowerCase()
    .replace(/['']/g, '')           // Remove apostrophes
    .replace(/[^a-z0-9]+/g, '-')    // Replace non-alphanumeric with hyphens
    .replace(/^-+|-+$/g, '');       // Trim leading/trailing hyphens
}

/**
 * Find a song in the catalog by its slug.
 * Compares by converting each title to a slug.
 */
export function findSongBySlug(
  catalog: SongSummary[],
  slug: string
): SongSummary | undefined {
  const normalizedSlug = slug.toLowerCase();
  return catalog.find(song => toSongSlug(song.title) === normalizedSlug);
}
