import { registerPlugin } from '@capacitor/core';
import type { CropBounds } from '@/types/pdf';

export interface CachedPdfInfo {
  path: string | null;
  isStale: boolean;
  crop?: CropBounds;
  cachedAt?: string;
}

export interface CacheStats {
  count: number;
  totalSizeBytes: number;
}

export interface NativePDFCachePlugin {
  /**
   * Download a PDF from URL and cache it locally
   */
  downloadPdf(options: {
    url: string;
    cacheKey: string;
    crop?: CropBounds;
  }): Promise<{ path: string; success: boolean }>;

  /**
   * Get the local file path for a cached PDF
   * Returns path: null if not cached
   * Returns isStale: true if cache is > 7 days old
   */
  getCachedPath(options: {
    cacheKey: string;
  }): Promise<CachedPdfInfo>;

  /**
   * Safely refresh a cached PDF (downloads new before deleting old)
   */
  refreshPdf(options: {
    url: string;
    cacheKey: string;
    crop?: CropBounds;
  }): Promise<{ path: string; success: boolean }>;

  /**
   * Clear all cached PDFs
   */
  clearCache(): Promise<{ success: boolean }>;

  /**
   * Get cache statistics
   */
  getCacheStats(): Promise<CacheStats>;
}

const NativePDFCache = registerPlugin<NativePDFCachePlugin>('NativePDFCache');

export default NativePDFCache;
