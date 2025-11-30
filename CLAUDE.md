# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Jazz Picker is a modern web interface for browsing and viewing jazz lead sheets, optimized for iPad music stands. It consists of:
- **Backend**: Flask API (Python) deployed on Fly.io
- **Frontend**: React + TypeScript + Vite application deployed on Vercel
- **Storage**: AWS S3 for PDFs, SQLite catalog (downloaded from S3 on startup)

The project serves ~735 songs with multiple variations per song (different keys, instruments, voice ranges) from Eric's lilypond lead sheets repository.

**Important**: This repo is only for the Jazz Picker web app. Eric maintains the LilyPond source files in a separate repo (`neonscribe/lilypond-lead-sheets`). We don't modify his LilyPond workflow - we only consume the output.

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

## Transposition Model (Key Concepts)

Understanding how keys and transpositions work is essential for this codebase.

### Terminology

| Term | Definition | Example |
|------|------------|---------|
| **Concert Key** | The key the audience hears. The "real" key. Always stored in DB/API/S3. | "Let's play in concert Eb" |
| **Written Key** | What appears on the chart for a specific instrument | Trumpet chart shows "F" |
| **Transposition** | The instrument category: C, Bb, Eb, or Bass | Trumpet is "Bb" |

### The Math

```
Written Key = Concert Key transposed UP by the instrument's interval

Concert Eb:
├─ C instruments (piano, guitar, bass):    Eb (written) — no transposition
├─ Bb instruments (trumpet, tenor sax):    F  (written) — up a major 2nd
└─ Eb instruments (alto sax, bari sax):    C  (written) — up a major 6th
```

### Band Example

If a band wants to play "Blue Bossa" in **concert Cm**, everyone plays together but sees different charts:

| Player | Instrument | Transposition | Written Key | Clef |
|--------|------------|---------------|-------------|------|
| Piano | C | - | Cm | Treble |
| Trumpet | Bb | +M2 | Dm | Treble |
| Alto Sax | Eb | +M6 | Am | Treble |
| Bass | C | - | Cm | Bass |

---

## User Experience Design

### User Setup
1. User signs up, picks instrument from fixed list (Trumpet, Alto Sax, Piano, etc.)
2. Instrument determines transposition and clef automatically
3. No separate instrument filter in header - user's instrument is the single source of truth

### Fixed Instrument List

```typescript
const INSTRUMENTS = [
  { id: 'piano',       label: 'Piano',       transposition: 'C',  clef: 'treble' },
  { id: 'guitar',      label: 'Guitar',      transposition: 'C',  clef: 'treble' },
  { id: 'trumpet',     label: 'Trumpet',     transposition: 'Bb', clef: 'treble' },
  { id: 'clarinet',    label: 'Clarinet',    transposition: 'Bb', clef: 'treble' },
  { id: 'tenor-sax',   label: 'Tenor Sax',   transposition: 'Bb', clef: 'treble' },
  { id: 'soprano-sax', label: 'Soprano Sax', transposition: 'Bb', clef: 'treble' },
  { id: 'alto-sax',    label: 'Alto Sax',    transposition: 'Eb', clef: 'treble' },
  { id: 'bari-sax',    label: 'Bari Sax',    transposition: 'Eb', clef: 'treble' },
  { id: 'bass',        label: 'Bass',        transposition: 'C',  clef: 'bass' },
  { id: 'trombone',    label: 'Trombone',    transposition: 'C',  clef: 'bass' },
];
```

### Browsing Songs
- User sees list of all 735 songs
- Search by title
- No instrument filter dropdown (removed)
- Header shows current instrument with hover hint: "Change in Settings"

### Song Card Display
- Song title
- Key pills showing **concert keys** that are cached for user's transposition
- Plus button to generate in custom concert key
- Default key comes from catalog (original key of the tune)

### Song Card Interactions
| Click Target | Action |
|--------------|--------|
| Song title | Load PDF in default concert key |
| Cached key pill | Load PDF in that concert key |
| Plus button | Open key picker to generate in custom concert key |

### Key Display (PDF Header, Key Picker)
| User's Transposition | Display for Concert Eb |
|----------------------|------------------------|
| C (Piano) | `Eb` |
| Bb (Trumpet) | `F for Trumpet (Concert Eb)` |
| Eb (Alto Sax) | `C for Alto Sax (Concert Eb)` |

Format for transposing instruments: `{written_key} for {instrument_label} (Concert {concert_key})`

### Setlists
- Store song title + concert key
- Each band member sees their own transposition
- Shareable (future feature)

---

## S3 Cache Structure

All PDFs are dynamically generated and cached in S3.

### Naming Convention

```
{song-slug}-{concert-key}-{transposition}-{clef}.pdf
```

**Examples:**
- `a-felicidade-a-C-treble.pdf` (Concert A, for piano)
- `a-felicidade-a-Bb-treble.pdf` (Concert A, for trumpet)
- `a-felicidade-a-Eb-treble.pdf` (Concert A, for alto sax)
- `blue-bossa-eb-Bb-treble.pdf` (Concert Eb, for trumpet)
- `autumn-leaves-g-C-bass.pdf` (Concert G, for bass)

### Query Pattern

To find cached concert keys for a song + transposition:
```
Prefix: {song-slug}-
Filter: files matching *-{transposition}-{clef}.pdf
Extract: concert key from filename
```

---

## Data Model

### Storage & API Convention

- **Catalog** stores song title + default concert key
- **Setlists** store song title + concert key
- **API** always uses concert key
- **S3 filenames** encode concert key + transposition + clef
- **Frontend** calculates written key for display based on user's instrument

### Generate Endpoint

```json
POST /api/v2/generate
{
  "song": "502 Blues",
  "concert_key": "eb",
  "transposition": "Bb",
  "clef": "treble",
  "instrument_label": "Trumpet"  // optional, for PDF subtitle
}

Response: {
  "url": "https://s3.../502-blues-eb-Bb-treble.pdf",
  "cached": true/false,
  "generation_time_ms": 7500
}
```

Backend calculates written key and passes to LilyPond.

---

## Architecture

### High-Level Structure

```
Frontend (React) → Backend API (Flask) → S3 PDFs
                                      ↓
                              catalog.db (SQLite)
```

### Backend (`app.py`)

**Key Responsibilities:**
- Serve paginated song list with search
- Return cached keys for a song (queries S3)
- Generate PDFs dynamically via LilyPond
- Cache generated PDFs in S3

**API Endpoints:**
- `GET /api/v2/songs?limit=50&offset=0&q=search` - Paginated song list
- `GET /api/v2/songs/:title/cached` - Get default key + cached concert keys from S3
- `POST /api/v2/generate` - Generate PDF (see Data Model section above)
- `GET /health` - Health check

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
4. Catalog contains ~735 songs with title + default concert key

### Frontend (`frontend/src/`)

**Architecture Pattern:**
- Component-based React with TypeScript
- React Query for server state management
- Tailwind CSS for styling
- Custom hooks for data fetching

**Key Components:**
- `App.tsx` - Main application orchestrator with infinite scroll and search
- `AuthGate.tsx` - Supabase sign in/up
- `WelcomeScreen.tsx` - Instrument selection (from fixed list)
- `Header.tsx` - Search bar, current instrument display
- `SongList.tsx` - Renders list of songs
- `SongListItem.tsx` - Song card with key pills and generate button
- `SetlistManager.tsx` - List/create/delete setlists
- `SetlistViewer.tsx` - View setlist songs, prefetch PDFs
- `PDFViewer.tsx` - iPad-optimized PDF viewer with:
  - Clean mode with auto-hide nav (2s timeout)
  - Portrait: single page | Landscape: side-by-side
  - Pinch zoom (0.3x-5x), swipe gestures
  - Keyboard shortcuts (arrows, F for fullscreen, Esc)
  - Setlist navigation (swipe L/R at first/last page to change songs)
  - Safe area support for iOS PWA mode
- `SettingsMenu.tsx` - Change instrument, logout

**State Management:**
- React Query for server data (songs, cached keys, PDF URLs)
- React `useState` for UI state (search query)
- LocalStorage for user instrument preference
- Smart prefetching: next page of songs loaded ahead of user scroll

**API Service (`services/api.ts`):**
- `getSongsV2()` - Paginated song list with search
- `getCachedKeys()` - Default key + cached concert keys for a song
- `generatePDF()` - Generate/fetch PDF

**Types (`types/catalog.ts`):**
- `SongSummary` - title, default_key, default_clef
- `InstrumentType`: 'C' | 'Bb' | 'Eb' | 'Bass'

### Catalog Generation (`build_catalog.py`)

Scans `lilypond-data/Wrappers/*.ly` files and extracts:
- Song title
- Default concert key
- Core file reference

Outputs:
- `catalog.db` - SQLite database with songs table

**Important Logic:**
- 729/735 songs have 1 core file
- 6 songs have 2 core files (alternative keys, guitar solos, bass lines)

### Data Flow

**Song Browsing:**
1. User searches in Header
2. App fetches songs via API
3. React Query prefetches next page as user scrolls
4. Intersection Observer triggers page increment when scroll reaches bottom

**PDF Viewing:**
1. User taps song title or key pill
2. Frontend calls `/api/v2/generate` with song + concert key + user's transposition
3. Backend checks S3 cache, generates if needed, returns presigned URL
4. PDFViewer fetches and displays PDF

## Important Implementation Details

### Frontend Infinite Scroll
- Uses `IntersectionObserver` to detect scroll position
- Prefetches next page when user approaches bottom (threshold: 0.1)
- Accumulates songs across pages in state array
- Resets on search change

### PDF Viewer Modes
- **Portrait**: Single-page view, swipe vertical
- **Landscape**: Side-by-side two pages, swipe horizontal
- **Clean Mode**: Auto-hides navigation after 2s of no interaction
- **Keyboard**: Arrow keys (next/prev page), F (fullscreen), Esc (exit)
- **Touch**: Pinch zoom, swipe gestures, tap top 20% to toggle nav

### S3 Integration
- All PDFs are dynamically generated and cached
- Naming: `{song-slug}-{concert-key}-{transposition}-{clef}.pdf`
- Presigned URLs expire after 15 minutes
- Backend handles cache check + generation + URL generation

### Authentication
- **Frontend**: Supabase auth (`AuthGate.tsx`)
- **Backend**: Optional basic auth (disabled by default, controlled via `REQUIRE_AUTH`)

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
- GitHub OIDC provider + IAM role (`jazz-picker-catalog-updater`) for auto-refresh workflow

**Not managed by Terraform:**
- Fly.io (uses `fly.toml` + `fly secrets`)
- IAM access keys (stored as Fly secrets)

### Auto-Refresh Catalog

When Eric pushes changes to `neonscribe/lilypond-lead-sheets`, a GitHub Action automatically:
1. Rebuilds `catalog.db` from the lilypond files
2. Uploads to S3 (using OIDC - no stored AWS credentials)
3. Restarts the Fly app to load the new catalog

The workflow lives in Eric's repo. A reference copy is in `.github/workflows/update-catalog.yml`.

**Manual refresh:**
```bash
python3 build_catalog.py
aws s3 cp catalog.db s3://jazz-picker-pdfs/catalog.db
fly apps restart jazz-picker
```

## Development Philosophy

- **Don't over-engineer for cost savings** - S3 storage is very cheap. Optimize for developer velocity and user experience first. Only optimize for cost when actual costs become a problem.
- **Keep it simple** - Avoid premature abstractions and over-architecting.
- **Ask before assuming** - When uncertain about current behavior, data sources, or user intent, ask clarifying questions rather than making assumptions. This is especially important when dealing with state that may have changed (caches, database content, S3 files).

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
├── .github/workflows/
│   └── update-catalog.yml    # Reference copy of auto-refresh workflow
├── infrastructure/           # Terraform (AWS resources)
│   ├── main.tf               # S3, IAM user, OIDC provider, IAM role
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
