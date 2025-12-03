import { registerPlugin } from '@capacitor/core';
import type { PluginListenerHandle } from '@capacitor/core';
import type { CropBounds } from '@/types/pdf';

export interface PDFItem {
  localPath?: string;   // Cached file path (preferred)
  remoteUrl?: string;   // S3 URL fallback
  title: string;
  key: string;
  crop?: CropBounds;
}

export interface NativePDFPlugin {
  // Single PDF (for browse/catalog viewing)
  open(options: {
    url: string;
    title?: string;
    key?: string;
    setlistIndex?: number;
    setlistTotal?: number;
    crop?: CropBounds;
  }): Promise<{ action: string }>;

  // Setlist viewing - pass all PDFs for fast navigation
  openSetlist(options: {
    items: PDFItem[];
    startIndex: number;
  }): Promise<{ action: string; finalIndex: number }>;

  addListener(
    eventName: 'nextSong',
    listenerFunc: () => void
  ): Promise<PluginListenerHandle>;

  addListener(
    eventName: 'prevSong',
    listenerFunc: () => void
  ): Promise<PluginListenerHandle>;
}

const NativePDF = registerPlugin<NativePDFPlugin>('NativePDF');

export default NativePDF;
