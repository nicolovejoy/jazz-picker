# Jazz Picker Frontend

React-based frontend for browsing Eric's jazz lead sheet collection, optimized for iPad music stand use.

## Features

- **Two-Filter System**: Select instrument (C, Bb, Eb, Bass) and singer range preference (Alto/Mezzo/Soprano, Baritone/Tenor/Bass, Standard, All)
- **Color-Coded Filters**: Visual indicators for different singer ranges (purple, green, gray, blue)
- **Search**: Real-time search across all songs
- **PDF Viewer**: iOS-compatible PDF rendering using PDF.js (handles multi-page charts)
- **Responsive Design**: Optimized for iPad with large touch targets

## Tech Stack

- React 19 + TypeScript
- Tailwind CSS v3
- React Query (data fetching/caching)
- PDF.js (PDF rendering)
- Vite (dev server + build tool)

## Development

### Prerequisites

- Node.js 20.18+
- Flask backend running on port 5001

### Setup

```bash
npm install
```

### Run Dev Server

```bash
npm run dev
```

Access at `http://localhost:5173`

### Build for Production

```bash
npm run build
npm run preview
```

## Known Issues (2025-11-14)

- [ ] **Filtering Bug**: Charts don't appear when selecting Bb/Eb/Bass instruments - filter logic is too strict
- [ ] **PDF Loading**: Charts fail to load in PDF viewer
- [ ] **UX Issues**: Need to refine user experience flow

## Configuration

- **Default Preferences**: C instrument + Alto/Mezzo/Soprano range
- **API Proxy**: `/api` and `/pdf` routes proxy to Flask backend at `localhost:5001`
- **Path Alias**: `@/` maps to `./src/`

## Project Structure

```
frontend/
├── src/
│   ├── components/       # React components
│   │   ├── Header.tsx    # Filter dropdowns
│   │   ├── SongList.tsx  # Song browser with search
│   │   └── PDFViewer.tsx # PDF.js-based viewer
│   ├── hooks/            # Custom React hooks
│   │   └── useSongs.ts   # React Query hook
│   ├── services/         # API layer
│   │   └── api.ts        # Fetch functions
│   ├── types/            # TypeScript types
│   │   └── catalog.ts    # Song/Variation types
│   ├── App.tsx           # Main app component
│   └── main.tsx          # Entry point
├── vite.config.ts        # Vite configuration
└── tailwind.config.js    # Tailwind configuration
```

## Next Steps

- Fix instrument filtering logic to show all relevant variations
- Debug PDF loading issues
- Add setlist functionality
- Save user preferences to localStorage
- PWA support for iPad home screen
