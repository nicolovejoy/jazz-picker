import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'org.pianohouseproject.jazzpicker',
  appName: 'Jazz Picker',
  webDir: 'dist',
  ios: {
    // Allow loading PDFs from S3
    allowsLinkPreview: false,
    scrollEnabled: true,
    contentInset: 'always',
  },
  plugins: {
    StatusBar: {
      style: 'dark',
      backgroundColor: '#000000',
    },
  },
};

export default config;
