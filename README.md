# Jazz Picker 🎵

Web app for browsing Eric's LilyPond jazz lead sheet collection. Flask backend will eventually compile PDFs via Docker (but for now stores copies locally and serves them), React frontend (in development) for iPad music stand use as well as for browsing on the web or eventually even small iOs devices.

## Quick Start

**Backend:**

```bash
python3 build_catalog.py  # Generate catalog.json (735 songs)
python3 app.py            # Runs on http://localhost:5001
```

**Frontend:**

```bash
cd frontend
npm install
npm run dev              # Runs on http://localhost:5173
```

**With Docker:**

```bash
docker-compose up --build  # See DOCKER_README.md
```

## Architecture

**Backend (Flask):**

- Catalog API: `/api/songs`, `/api/songs/search`
- S3 presigned URLs: `/pdf/<filename>` (15min expiry)
- Graceful fallback: S3 → cache → Dropbox → compile
- CORS configured for browser access

**Frontend (React):**

- Two-filter system: Instrument + Singer Range
- Search across 735 songs (4000+ variations)
- PDF viewer with orientation detection
  - **Portrait mode:** 1 page, swipe navigation
  - **Landscape mode:** 2 pages side-by-side (music stand view)
- Touch gestures for page navigation
- Optimized for iPad music stand use

## Project Structure

```
├── app.py                    # Flask backend (port 5001)
├── build_catalog.py          # Generate catalog.json
├── catalog.json              # 735 songs, 4000+ variations
├── frontend/                 # React app (port 5173)
│   ├── src/components/       # Header, SongList, PDFViewer
│   └── README.md             # Frontend docs
├── lilypond-data/
│   ├── Wrappers/             # 4000+ .ly files
│   └── Core/                 # 735 core files
└── DOCKER_README.md          # Docker setup
```

## Status

**Working:**

- ✅ Backend API with S3 presigned URLs
- ✅ React UI with filtering/search
- ✅ PDF viewing with S3 storage (2GB, 4367 files)
- ✅ AWS S3 integration with CORS
- 🔄 Docker setup (available but not required for S3 workflow)

**Features:**

- 🎵 Browse 735 jazz standards with 4000+ transposed variations
- 🔍 Real-time search and filtering (instrument, singer range)
- 📱 iPad-optimized PDF viewer
  - Portrait: Single page with swipe navigation
  - Landscape: Side-by-side pages (sheet music reading)
- ☁️ S3 storage with instant presigned URL access
- 🎹 Compiled by Eric using LilyPond

**Next Steps:**

- Add setlist functionality (save song collections)
- Implement user preferences (remember filters)
- PWA support for offline use
- API refinements (see ARCHITECTURE.md)

See `frontend/README.md` for frontend details.
