# Jazz Picker Frontend - Week 2 Plan

## Overview
Simple single-page React app for browsing and viewing jazz lead sheets.

**Target User:** iPad music stand - browse songs, tap, view PDF

## Tech Stack
- Vite + React 19 + TypeScript
- Tailwind CSS (styling)
- React Query (API calls)
- PDF.js (PDF viewing)
- React Icons (icons)
- NO routing (single page app)
- NO Zustand (simple component state)

## UI Design
```
┌─────────────────────────────────────────┐
│  Jazz Picker  🎵           [600 songs]  │
├─────────────┬───────────────────────────┤
│ Search: ___ │                           │
│ Filter: All │      PDF Viewer           │
│             │    (Selected Song)        │
│ Song List   │                           │
│ □ All My.. │                           │
│ □ Autumn.. │                           │
│ □ Blue Bo.. │                           │
│ ...         │                           │
└─────────────┴───────────────────────────┘
```

## API Endpoints (Flask)
- `GET /api/songs` - Get all songs
- `GET /api/songs/search?q=query` - Search songs
- `GET /pdf/<filename>` - Get PDF (cached or compiled)

## Directory Structure
```
frontend/
├── src/
│   ├── components/
│   │   ├── SongList.tsx      # Song browser with search
│   │   ├── PDFViewer.tsx     # PDF.js viewer
│   │   └── Header.tsx        # Top bar
│   ├── services/
│   │   └── api.ts            # API client for Flask
│   ├── types/
│   │   └── catalog.ts        # TypeScript types for songs
│   ├── App.tsx               # Main app (layout)
│   ├── main.tsx              # Entry point
│   └── index.css             # Tailwind imports
├── vite.config.ts            # Vite config (proxy to :5001)
├── tailwind.config.ts        # Tailwind config
└── package.json              # Dependencies
```

## Implementation Steps

### ✅ Phase 1: Setup (COMPLETED)
- [x] Create Vite project with React + TypeScript
- [x] Document plan

### 🔄 Phase 2: Configuration (IN PROGRESS)
- [ ] Install dependencies
- [ ] Configure Vite (proxy to Flask :5001, @ alias)
- [ ] Set up Tailwind CSS
- [ ] Create directory structure

### ⏳ Phase 3: Types & API
- [ ] Create TypeScript types from catalog.json
- [ ] Build API service layer
- [ ] Set up React Query provider

### ⏳ Phase 4: Components
- [ ] Header component (title, stats)
- [ ] SongList component (search, filter, list)
- [ ] PDFViewer component (PDF.js integration)

### ⏳ Phase 5: Integration
- [ ] Main App layout (grid/flex)
- [ ] Connect components to API
- [ ] Test full flow: search → select → view PDF

### ⏳ Phase 6: Polish
- [ ] Mobile-responsive (iPad optimized)
- [ ] Loading states
- [ ] Error handling
- [ ] Empty states

## Dependencies to Install
```json
{
  "dependencies": {
    "react": "^19.1.0",
    "react-dom": "^19.1.0",
    "@tanstack/react-query": "^5.80.0",
    "pdfjs-dist": "^4.0.0",
    "react-icons": "^5.0.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.3.0",
    "vite": "^5.0.0",
    "typescript": "^5.5.0",
    "tailwindcss": "^3.4.0",
    "autoprefixer": "^10.4.0",
    "postcss": "^8.4.0"
  }
}
```

## Vite Config
- Dev server: `localhost:5173`
- Proxy `/api` and `/pdf` → `http://localhost:5001`
- Path alias: `@/` → `./src/`

## Flask Backend (Already Running)
- Port: 5001
- Endpoints ready
- Docker/LilyPond working
- 3-tier caching in place

## Notes
- Keep it simple - this is a music stand app
- Focus on iPad usability (large touch targets)
- PDF viewing is the core feature
- Search needs to be fast (600+ songs)

## Current Status
**Last Updated:** 2025-11-14

Building Phase 2 - Configuration...
