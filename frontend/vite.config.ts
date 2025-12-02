import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  define: {
    __BUILD_TIME__: JSON.stringify(
      new Date().toISOString().slice(0, 16).replace('T', ' ')
    ),
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'https://jazz-picker.fly.dev',
        changeOrigin: true,
        secure: true,
      },
      '/pdf': {
        target: 'https://jazz-picker.fly.dev',
        changeOrigin: true,
        secure: true,
      },
    },
  },
})
