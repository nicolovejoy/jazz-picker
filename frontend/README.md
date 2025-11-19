# Jazz Picker Frontend

React app for browsing jazz lead sheets. Optimized for iPad music stand use.

## Quick Start

```bash
npm install
npm run dev      # http://localhost:5173
```

Requires Flask backend on port 5001.

## Features

- Two-filter system: Instrument (C/Bb/Eb/Bass) + Singer Range
- Real-time search across 735 songs (4000+ variations)
- **PDF Viewer** with orientation-aware display:
  - **Portrait mode:** Single page view, swipe to navigate
  - **Landscape mode:** Side-by-side pages (perfect for music stands!)
  - Touch gestures for page navigation (swipe left/right)
  - Navigation buttons with page indicator
- Color-coded filter dropdowns
- S3-powered PDF delivery with presigned URLs

## Tech Stack

- React 19 + TypeScript
- Tailwind CSS v3
- React Query
- react-pdf (PDF rendering)
- Vite (dev server, proxies to :5001)

## Structure

```
src/
├── components/
│   ├── Header.tsx       # Filters (working)
│   ├── SongList.tsx     # Browser (working)
│   └── PDFViewer.tsx    # Viewer (broken)
├── services/api.ts      # API client
├── types/catalog.ts     # TypeScript types
└── App.tsx              # Main app
```

## Current Status

**✅ Fully Functional!**

- S3 storage with CORS configured
- Presigned URLs (15min expiry) for secure PDF access
- PDF.js worker loading from unpkg CDN
- Landscape/portrait mode auto-detection
- Swipe gestures for navigation
- Network access enabled for iPad

**iPad Usage:**
1. Connect iPad to same WiFi as dev machine
2. Open: `http://YOUR_IP:5173` (shown in terminal)
3. Rotate to landscape for side-by-side pages
4. Swipe or tap arrows to navigate

**For Eric's Workflow:**
See `S3_SETUP.md` for syncing PDFs after compilation.
