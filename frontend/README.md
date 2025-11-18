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
- Real-time search across 735 songs
- PDF viewer (currently broken - PDF.js worker issues)
- Color-coded filter dropdowns

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

**✅ PDF Viewing Working!**

- S3 storage configured with CORS
- Presigned URLs for secure PDF access
- Worker loading from unpkg CDN

**For Eric's Workflow:**
See `S3_SETUP.md` for syncing PDFs after compilation.
