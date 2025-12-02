import { registerPlugin } from '@capacitor/core';
import type { PluginListenerHandle } from '@capacitor/core';
import type { CropBounds } from '@/types/pdf';

export interface NativePDFPlugin {
  open(options: {
    url: string;
    title?: string;
    key?: string;
    setlistIndex?: number;
    setlistTotal?: number;
    crop?: CropBounds;
  }): Promise<{ action: string }>;

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
