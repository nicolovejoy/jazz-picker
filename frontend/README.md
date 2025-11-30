# Jazz Picker Frontend

React app for browsing jazz lead sheets. Optimized for iPad music stand use.

## Quick Start

```bash
npm install
npm run dev      # http://localhost:5173
```

Uses deployed backend at https://jazz-picker.fly.dev via Vite proxy.

## Features

- **Song Browser:** Search, infinite scroll, instrument-aware key display
- **Setlists:** Create, share (public/private), deep-linkable URLs
- **PDF Viewer:** iPad-optimized with auto-hide nav, pinch zoom, swipe gestures, landscape side-by-side view
- **Multi-instrument:** Each user sees charts in their instrument's transposition + clef
- **PWA Support:** Add to home screen for app-like experience

## Tech Stack

React 19, TypeScript, Tailwind CSS, React Query, Supabase, react-pdf, Vite

## Structure

```
src/
├── components/
│   ├── Header.tsx          # Search + instrument display
│   ├── SongList.tsx        # Song browser with key pills
│   ├── SetlistManager.tsx  # List/create/delete setlists
│   ├── SetlistViewer.tsx   # View setlist, copy link, prefetch
│   ├── PDFViewer.tsx       # iPad-optimized viewer
│   └── SettingsMenu.tsx    # Instrument selection
├── services/
│   ├── api.ts              # Backend API client
│   └── setlistService.ts   # Supabase setlist operations
├── hooks/                  # React Query hooks
├── contexts/               # Auth context
├── types/                  # TypeScript types
└── App.tsx                 # Main app with URL routing
```
