# Jazz Picker Frontend

React app for browsing jazz lead sheets. Optimized for iPad music stand use.

## Quick Start

```bash
npm install
npm run dev      # http://localhost:5173
```

Uses deployed backend at https://jazz-picker.fly.dev via Vite proxy.

## Features

- **4-Context Navigation:** Browse, Spin the Dial, Setlist, More (settings)
- **Song Browser:** Search, infinite scroll, hover/long-press actions
- **Setlists:** Create, share (public/private), deep-linkable URLs
- **PDF Viewer:** iPad-optimized with auto-hide nav, pinch zoom, swipe gestures
- **Multi-instrument:** Each user sees charts in their instrument's transposition + clef
- **PWA Support:** Full-screen mode, add to home screen

## Tech Stack

React 19, TypeScript, Tailwind CSS, React Query, Supabase, react-pdf, Vite

## Structure

```
src/
├── components/
│   ├── BottomNav.tsx       # 4-context navigation
│   ├── Header.tsx          # Slim header with search
│   ├── SongList.tsx        # Song grid (1/2/3 columns)
│   ├── SongListItem.tsx    # Card with hover/long-press actions
│   ├── AddToSetlistModal.tsx
│   ├── SetlistManager.tsx  # List/create/delete setlists
│   ├── SetlistViewer.tsx   # View setlist, prefetch PDFs
│   ├── PDFViewer.tsx       # iPad-optimized viewer
│   └── GenerateModal.tsx   # Custom key picker
├── services/
│   ├── api.ts              # Backend API client
│   └── setlistService.ts   # Supabase setlist operations
├── hooks/                  # React Query hooks
├── contexts/               # Auth context
├── types/                  # TypeScript types
└── App.tsx                 # Context switching, routing
```

## Contexts

| Context | Description |
|---------|-------------|
| Browse | Search songs, view PDFs, add to setlist |
| Spin | Random song practice (placeholder) |
| Setlist | View/edit setlists, perform mode |
| More | Settings, about, sign out |
