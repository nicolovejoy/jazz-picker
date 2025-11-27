# Jazz Picker Frontend

React app for browsing jazz lead sheets. Optimized for iPad music stand use.

## Quick Start

```bash
npm install
npm run dev      # http://localhost:5173
```

Uses deployed backend at https://jazz-picker.fly.dev via Vite proxy.

## Features

- **Song Browser:** Instrument filter (C/Bb/Eb/Bass), search, infinite scroll
- **PDF Viewer:** iPad-optimized with auto-hide nav, pinch zoom, swipe gestures, landscape side-by-side view
- **PWA Support:** Add to home screen for app-like experience

## Tech Stack

React 19, TypeScript, Tailwind CSS, React Query, react-pdf, Vite

## Structure

```
src/
├── components/
│   ├── Header.tsx       # Search + filters
│   ├── SongList.tsx     # Song browser
│   └── PDFViewer.tsx    # iPad-optimized viewer
├── services/api.ts      # API client
├── types/catalog.ts     # TypeScript types
└── App.tsx              # Main app
```
