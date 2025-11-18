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

**Backend (Flask):** (Claude, let's discuss this approach)

- Catalog API: `/api/songs`, `/api/songs/search`
- PDF serving: `/pdf/<filename>`
- LilyPond compilation via Docker
- 3-tier caching: cache dir → Dropbox → compile

**Frontend (React):** (Claude, let's discuss the API between the front end and the back end as well as the data models for the conversation between them)

- Two-filter system: Instrument + Singer Range
- Search across 735 songs
- PDF viewer (currently broken - worker issues)
- Optimized for iPad

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

**Next Steps:**

- Refine API endpoints (see ARCHITECTURE.md)
- Add setlist functionality
- Implement user preferences
- PWA support for offline use

See `frontend/README.md` for frontend details.
