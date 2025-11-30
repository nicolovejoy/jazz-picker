# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Jazz Picker is a modern web interface for browsing and viewing jazz lead sheets, optimized for iPad music stands. It consists of:
- **Backend**: Flask API (Python) deployed on Fly.io
- **Frontend**: React + TypeScript + Vite application (local development, Cloudflare Pages planned)
- **Storage**: AWS S3 for PDFs, SQLite catalog (downloaded from S3 on startup)

The project serves ~735 songs with multiple variations per song (different keys, instruments, voice ranges) from Eric's lilypond lead sheets repository.

## Development Commands

### Backend Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run local development server
python3 app.py
# Runs on http://localhost:5001

# Build/update catalog from lilypond files
python3 build_catalog.py
# Outputs: catalog.json (5.7MB) and catalog.db (SQLite)

# Sync PDFs to S3 (Eric's workflow only)
./sync_pdfs_to_s3.sh         # Production sync
./sync_pdfs_to_s3.sh --dryrun  # Test without uploading
```

### Frontend Development

```bash
cd frontend

# Install dependencies
npm install

# Run development server (uses deployed backend via proxy)
npm run dev
# Runs on http://localhost:5173

# Build for production
npm run build
# Output: frontend/dist

# Lint code
npm run lint

# Preview production build
npm preview
```

### Deployment

```bash
# Deploy backend to Fly.io
fly deploy

# View backend logs
fly logs

# Set environment variables
fly secrets set REQUIRE_AUTH=true
fly secrets set AWS_ACCESS_KEY_ID=xxx
fly secrets set AWS_SECRET_ACCESS_KEY=xxx
```

### Local Backend Development (Optional)

By default, the frontend uses the deployed backend (https://jazz-picker.fly.dev) via Vite proxy. To develop against a local backend:

1. Run backend: `python3 app.py` (port 5001)
2. Update `frontend/vite.config.ts` proxy target to `http://localhost:5001`
3. Run frontend: `cd frontend && npm run dev`

## Architecture

### High-Level Structure

```
Frontend (React) → Backend API (Flask) → S3 PDFs
                                      ↓
                              catalog.json (metadata)
```

### Backend (`app.py`)

**Key Responsibilities:**
- Serve paginated song lists with filtering (API v2)
- Provide song detail with all variations
- Generate S3 presigned URLs for PDFs (15min expiration)
- Optional basic auth

**API Endpoints:**
- `GET /api/v2/songs?limit=50&offset=0&q=search&instrument=C` - Paginated song list
- `GET /api/v2/songs/:title` - Song detail with variations
- `GET /pdf/:filename` - Returns S3 presigned URL as JSON
- `POST /api/v2/generate` - Generate PDF in any key (see below)
- `GET /health` - Health check

**Generate Endpoint:**
```json
POST /api/v2/generate
{"song": "502 Blues", "key": "d", "clef": "treble"}

Response: {"url": "https://s3.../generated/...", "cached": true/false, "generation_time_ms": 7500}
```

**Environment Variables:**
- `USE_S3=true` - Enable S3 integration
- `S3_BUCKET_NAME=jazz-picker-pdfs`
- `S3_REGION=us-east-1`
- `REQUIRE_AUTH=false` - Enable/disable basic auth
- `BASIC_AUTH_USERNAME`, `BASIC_AUTH_PASSWORD` - Auth credentials

**Data Loading:**
1. Downloads `catalog.db` (SQLite) from S3 on startup
2. Falls back to local file if S3 unavailable
3. Uses `db.py` module for all database queries
4. Catalog contains ~735 songs with metadata for ~4366 variations

### Frontend (`frontend/src/`)

**Architecture Pattern:**
- Component-based React with TypeScript
- React Query for server state management
- Tailwind CSS for styling
- Custom hooks for data fetching

**Key Components:**
- `App.tsx` - Main application orchestrator with infinite scroll, filters, search
- `Header.tsx` - Navigation with filters (Instrument + Singer Range)
- `SongList.tsx` - Renders list of songs
- `SongListItem.tsx` - Individual song item with smart navigation (auto-open single variations, Enter key)
- `PDFViewer.tsx` - iPad-optimized PDF viewer with:
  - Clean mode with auto-hide nav (2s timeout)
  - Portrait: single page | Landscape: side-by-side
  - Pinch zoom (0.3x-5x), swipe gestures
  - Keyboard shortcuts (arrows, F for fullscreen, Esc)
- `SettingsMenu.tsx` - Global user preferences

**State Management:**
- React Query for server data (songs, song details, PDF URLs)
- React `useState` for UI state (filters, search, selected variation)
- LocalStorage for user preferences
- Smart prefetching: next page of songs loaded ahead of user scroll

**API Service (`services/api.ts`):**
- Centralized API client
- Handles both JSON responses and S3 presigned URLs
- Error handling with user-friendly messages

**Types (`types/catalog.ts`):**
- `SongSummary`, `SongDetail`, `Variation` - Data models
- `InstrumentType`: 'C' | 'Bb' | 'Eb' | 'Bass' | 'All'

### Catalog Generation (`build_catalog.py`)

Scans `lilypond-data/Wrappers/*.ly` files and extracts:
- Song title, key, instrument, clef
- Variation type (Standard, Alto Voice, Baritone Voice, Bass, Bb, Eb)
- Core file reference
- Expected PDF output path

Outputs:
- `catalog.json` - Full catalog (5.7MB, backwards compatible)
- `catalog.db` - SQLite database (1.3MB, for future use)

**Important Logic:**
- 729/735 songs have 1 core file
- 6 songs have 2 core files (alternative keys, guitar solos, bass lines)
- PDF paths constructed based on variation type to correct S3 category folder

### Data Flow

**Song Browsing:**
1. User applies filters/search in Header
2. App resets to page 0, fetches first 50 songs via API v2
3. React Query prefetches next page as user scrolls
4. Intersection Observer triggers page increment when scroll reaches bottom
5. Songs accumulate in `allSongs` state array

**PDF Viewing:**
1. User selects variation from SongListItem
2. Frontend calls `/pdf/:filename` endpoint
3. Backend generates S3 presigned URL (15min TTL)
4. Backend returns JSON `{"url": "https://s3...", "expires_at": "..."}`
5. PDFViewer fetches PDF from presigned URL using react-pdf
6. Auto-hide navigation activates after 2s of inactivity

## Important Implementation Details

### Frontend Infinite Scroll
- Uses `IntersectionObserver` to detect scroll position
- Prefetches next page when user approaches bottom (threshold: 0.1)
- Accumulates songs across pages in state array
- Resets on filter/search change

### Smart Navigation in Song List
- If song has exactly 1 variation: auto-opens PDF viewer
- If song has multiple variations: shows variation list
- Enter key navigates into song/variation
- Escape key navigates back

### PDF Viewer Modes
- **Portrait**: Single-page view, swipe vertical
- **Landscape**: Side-by-side two pages, swipe horizontal
- **Clean Mode**: Auto-hides navigation after 2s of no interaction
- **Keyboard**: Arrow keys (next/prev page), F (fullscreen), Esc (exit)
- **Touch**: Pinch zoom, swipe gestures, tap top 20% to toggle nav

### Filter Logic
- **Instrument Filter**: Filters variations by instrument type (C, Bb, Eb, Bass)
- Voice variations are separate from instrument filters

### S3 Integration
- PDFs stored in folders: `Standard/`, `Alto-Voice/`, `Baritone-Voice/`, etc.
- Presigned URLs expire after 15 minutes
- Backend handles URL generation transparently
- Frontend receives presigned URL as JSON response

### Authentication
- Optional basic auth (disabled by default)
- Controlled via `REQUIRE_AUTH` environment variable
- Uses standard HTTP Basic Authentication
- Currently no frontend login UI (API-level only)

## Infrastructure

AWS resources are managed via Terraform in `infrastructure/`:

```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

**Managed resources:**
- S3 bucket (`jazz-picker-pdfs`)
- IAM user (`jazz-picker-api`) with read + write (generated/ only) policies

**Not managed by Terraform:**
- Fly.io (uses `fly.toml` + `fly secrets`)
- IAM access keys (stored as Fly secrets)

## Known Issues & Context

1. **No Tests**: Project currently has no test suite.

2. **Symlinks**: Root directory contains symlinks to Dropbox folders - don't modify these.

3. **Database**: Backend uses SQLite (`catalog.db`) via `db.py` module. JSON catalog is deprecated.

4. **LilyPond Version**: Eric's lilypond-data requires LilyPond 2.25 (development branch). The Dockerfile downloads it from GitLab releases. Debian/Ubuntu apt only provides 2.24.

## Common Patterns

### Adding a New API Endpoint

1. Add endpoint handler in `app.py`:
```python
@app.route('/api/v2/endpoint', methods=['GET'])
@requires_auth
def endpoint_handler():
    # implementation
    return jsonify(response_data)
```

2. Add TypeScript types in `frontend/src/types/catalog.ts`

3. Add API method in `frontend/src/services/api.ts`:
```typescript
async getEndpoint(): Promise<ResponseType> {
  const response = await fetch(`${API_BASE}/v2/endpoint`);
  if (!response.ok) throw new Error('Failed to fetch');
  return response.json();
}
```

4. Create React Query hook in `frontend/src/hooks/`:
```typescript
export function useEndpoint() {
  return useQuery({
    queryKey: ['endpoint'],
    queryFn: () => api.getEndpoint(),
  });
}
```

### Adding a New Component

1. Create component file: `frontend/src/components/ComponentName.tsx`
2. Use TypeScript with proper prop types
3. Use Tailwind CSS for styling (no custom CSS files)
4. Import types from `@/types/catalog`
5. Use React Query hooks for data fetching

### Modifying Catalog Structure

1. Update parsing logic in `build_catalog.py`
2. Run `python3 build_catalog.py` to regenerate catalog files
3. Update TypeScript types in `frontend/src/types/catalog.ts`
4. Update API response formatting in `app.py` if needed
5. Test with both local and S3 modes

## File Structure Reference

```
jazz-picker/
├── app.py                    # Flask backend
├── db.py                     # SQLite database access layer
├── build_catalog.py          # Catalog generation
├── catalog.db                # SQLite catalog (downloaded from S3)
├── fly.toml                  # Fly.io config
├── Dockerfile.prod           # Production Docker (includes LilyPond)
├── infrastructure/           # Terraform (AWS resources)
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── frontend/
    └── src/
        ├── App.tsx
        ├── components/
        ├── hooks/
        ├── services/
        └── types/
```
