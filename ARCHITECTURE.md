# Jazz Picker - Architecture & API Design

## Deployment Architecture

### Recommended Stack

```
┌─────────────────────────────────────────────────────────────┐
│                      USER (iPad/Web)                         │
└────────────┬────────────────────────────┬───────────────────┘
             │                            │
             │ React App                  │ PDF Downloads
             ▼                            ▼
┌────────────────────────┐    ┌──────────────────────────────┐
│   Cloudflare Pages     │    │   AWS S3                     │
│   (React/Vite)         │    │   (2GB, 4367 PDFs)           │
│   • Free unlimited BW  │    │   • Presigned URLs           │
│   • Global edge CDN    │    │   • $0.05/month storage      │
│   • 20s deploys        │    │   • Manual sync from Dropbox │
└────────────┬───────────┘    └──────────┬───────────────────┘
             │ API Calls                 │
             ▼                            │
┌────────────────────────┐               │
│   Fly.io               │───────────────┘
│   (Flask Backend)      │    Generates presigned URLs
│   • 512MB RAM          │
│   • $6/month           │
│   • No cold starts     │
│   • Docker-based       │
└────────────────────────┘
```

### Component Responsibilities

**Cloudflare Pages** (Frontend)

- Serve static React/Vite build
- Global edge delivery for instant loading
- Automatic HTTPS, unlimited bandwidth
- GitHub-based deployments

**Fly.io** (Backend)

- Flask API endpoints
- Catalog search and filtering
- Generate S3 presigned URLs for PDFs
- Always-on (no cold starts)

**AWS S3** (Storage)

- Store 4,367 compiled PDFs (2GB)
- Serve PDFs directly to users via presigned URLs
- Manual sync from Erik's Dropbox compilations (automated later)

### Why This Stack?

| Component         | Alternative   | Why Not?                                                                      |
| ----------------- | ------------- | ----------------------------------------------------------------------------- |
| Cloudflare Pages  | Vercel        | Vercel has 100GB bandwidth limit ($20/mo after); Cloudflare is unlimited free |
| Cloudflare Pages  | Netlify       | Slower deploys (50s vs 20s); same bandwidth limits as Vercel                  |
| Fly.io            | Railway       | Railway costs $15-20/mo vs Fly.io $6/mo for same specs                        |
| Fly.io            | Render        | Free tier has cold starts (bad UX); paid tier starts at $25/mo                |
| Fly.io            | AWS Lambda    | Cold starts (1-5s) unacceptable for music stand use                           |
| S3 presigned URLs | Backend proxy | Wastes bandwidth/$ by routing 2GB through Flask                               |

### Cost Breakdown

**Current (Development):**

- Cloudflare Pages: $0
- Fly.io: $0 (free tier, or ~$3-6/mo for paid)
- S3: $0.05/mo (storage only)
- **Total: ~$0-6/month**

**At Scale (100 active users):**

- Cloudflare Pages: $0 (still free)
- Fly.io: $6/mo
- S3 storage: $0.05/mo
- S3 requests: ~$0.20/mo
- S3 transfer: $0 (to CloudFront) or $8.50 (direct, 100GB)
- **Total: ~$6-15/month**

---

## API Design

### Current Issues

**1. Bloated Responses**

- `/api/songs` returns 5.4MB JSON (all 735 songs × 6 variations each)
- Contains server-side fields not needed by client (filepath, pdf_path, core_file, clef)
- No pagination or lazy loading
- Every page load fetches entire catalog

**2. Mixed Concerns**

- Server-side routing details (filepath, pdf_path) sent to client
- Client can't easily filter by user preferences server-side

**3. Inefficient Filtering**

- All filtering happens client-side after downloading 5.4MB
- Search requires full catalog in memory

### Proposed API v2

#### Principle: Slim Client, Rich Server

**Server-side data** (catalog.json):

- Keep all fields: filepath, pdf_path, core_file, clef, etc.
- Used for routing, compilation, internal logic
- Never exposed directly to client

**Client-side data** (API responses):

- Only fields needed for UI rendering and user interaction
- Minimal size for fast loading
- Filtered by user preferences

---

### Endpoint Proposals

#### 1. Get Songs List (Initial Load)

**Endpoint:** `GET /api/songs`

**Query Params:**

- `instrument` (optional): `C`, `Bb`, `Eb`, `Bass`, `All`
- `range` (optional): `Alto`, `Baritone`, `Standard`, `All`
- `limit` (optional): number, default 50
- `offset` (optional): number, default 0

**Response:** (Slim) -- Claude, how do we handle the different keys that the song is available in? remember, eventually the user will simply select the key they wanted in and be able to transpose any song into any of the 12 available keys but for now we just wanna start with the ones that we have a PDF for.

```json
{
  "songs": [
    {
      "title": "A Child Is Born",
      "variation_count": 6,
      "available_instruments": ["C", "Bb", "Eb"],
      "available_ranges": ["Alto", "Baritone", "Standard"]
    }
  ],
  "total": 735,
  "limit": 50,
  "offset": 0
}
```

**Size:** ~50KB (vs current 5.4MB)

---

#### 2. Get Song Details (On Demand)

**Endpoint:** `GET /api/songs/:title`

**Query Params:**

- `instrument` (optional): filter variations
- `range` (optional): filter variations

**Response:**

```json
{
  "title": "A Child Is Born",
  "variations": [
    {
      "id": "a-child-is-born-db-alto",
      "display_name": "A Child Is Born - Db",
      "key": "Db",
      "instrument": "Carmen McRae Key",
      "variation_type": "Alto Voice",
      "filename": "A Child Is Born - Ly - Db Alto Voice.ly"
    }
  ]
}
```

**Usage:**

- Fetch when user clicks song title
- Show variations in modal/dropdown
- Pre-filter by user's instrument/range preferences

---

#### 3. Search Songs

**Endpoint:** `GET /api/songs/search`

**Query Params:**

- `q` (required): search query
- `instrument` (optional)
- `range` (optional)
- `limit` (optional): default 20

**Response:** (Same format as songs list)

```json
{
  "songs": [
    {
      "title": "Here's That Rainy Day",
      "variation_count": 5,
      "available_instruments": ["C", "Bb", "Eb", "Bass"],
      "available_ranges": ["Alto", "Standard"]
    }
  ],
  "total": 12,
  "query": "rainy"
}
```

---

#### 4. Get PDF (Presigned URL)

**Endpoint:** `GET /api/pdf/:filename`

**Response:**

```json
{
  "url": "https://jazz-picker-pdfs.s3.amazonaws.com/...[presigned-url]...",
  "expires_at": "2025-11-17T20:30:00Z",
  "size_bytes": 150816,
  "cached": true
}
```

**Behavior:**

1. Backend checks local cache first
2. If not cached, generates S3 presigned URL (15min expiry)
3. Client fetches PDF directly from S3 (no proxy)
4. Backend caches URL for subsequent requests

**Why presigned URLs?**

- No bandwidth cost to Flask backend (PDFs bypass server)
- Fast downloads (direct from S3, not proxied)
- Secure (time-limited, signed)
- Reduced server load

---

#### 5. Check PDF Status (Optional)

**Endpoint:** `GET /api/pdf/:filename/status`

**Response:**

```json
{
  "exists": true,
  "cached": true,
  "size_bytes": 150816,
  "s3_key": "Alto-Voice/A-Child-Is-Born-Ly-Db-Alto-Voice.pdf"
}
```

**Usage:**

- Pre-check before showing PDF viewer
- Show loading indicator if not cached

---

### Data Models

#### Server-Side (catalog.json) - Keep Rich

```python
# Full variation data (internal use only)
{
  "filename": "A Child Is Born - Ly - Db Alto Voice.ly",
  "filepath": "lilypond-data/Wrappers/...",  # For compilation
  "title": "A Child Is Born",
  "key_and_variation": "Db Alto Voice",
  "pdf_path": "../Alto Voice/A Child Is Born...",  # For S3 mapping
  "display_name": "A Child Is Born - Db",
  "instrument": "Carmen McRae Key",
  "key": "Db",
  "clef": "treble_8",  # For LilyPond
  "core_file": "A Child Is Born - Ly Core - Db.ly",  # For compilation
  "variation_type": "Alto Voice"
}
```

**Keep all fields** - used for:

- S3 key generation (`pdf_path` → S3 key)
- Future LilyPond compilation
- Internal routing and logic

---

#### Client-Side (API responses) - Slim

```typescript
// Variation type for frontend
interface Variation {
  id: string; // Unique identifier (derived from filename)
  display_name: string; // "A Child Is Born - Db"
  key: string; // "Db" (show in UI)
  instrument: string; // "Carmen McRae Key" (description)
  variation_type: string; // "Alto Voice" (for filtering)
  filename: string; // For PDF fetching
}

// Song type for lists
interface SongSummary {
  title: string;
  variation_count: number;
  available_instruments: InstrumentType[];
  available_ranges: SingerRangeType[];
}

// Song type for detail view
interface SongDetail {
  title: string;
  variations: Variation[];
}
```

**Removed fields:**

- `filepath` - server-side only
- `pdf_path` - server-side only
- `core_file` - not relevant to users
- `clef` - not relevant to users
- `key_and_variation` - redundant with `display_name`

---

### S3 Integration Approach

#### Path Mapping

**Catalog pdf_path:**

```
"../Alto Voice/A Child Is Born - Ly - Db Alto Voice"
```

**S3 key:**

```
"Alto-Voice/A-Child-Is-Born-Ly-Db-Alto-Voice.pdf"
```

**Transformation:**

```python
def catalog_path_to_s3_key(pdf_path: str) -> str:
    """Convert catalog pdf_path to S3 key."""
    # Remove leading "../"
    path = pdf_path.replace('../', '')

    # Replace spaces with hyphens (optional, for clean URLs)
    path = path.replace(' ', '-')

    # Add .pdf extension
    return f"{path}.pdf"
```

---

#### S3 Upload Strategy

**Manual Sync (Initial):**

```bash
#!/bin/bash
# sync_pdfs_to_s3.sh

# Sync from Dropbox symlinks to S3
aws s3 sync "Alto Voice/" s3://jazz-picker-pdfs/Alto-Voice/ \
  --include "*.pdf" --exclude "*" --dryrun

aws s3 sync "Baritone Voice/" s3://jazz-picker-pdfs/Baritone-Voice/ \
  --include "*.pdf" --exclude "*" --dryrun

aws s3 sync "Standard/" s3://jazz-picker-pdfs/Standard/ \
  --include "*.pdf" --exclude "*" --dryrun

# Remove --dryrun when ready to upload
```

**Future Automation (Phase 2):**

- Watch Dropbox folder for changes
- Trigger S3 sync on new/updated PDFs
- Send notification when new songs available

---

#### Backend Implementation

```python
# app.py
import boto3
from datetime import datetime, timedelta

s3_client = boto3.client('s3',
    region_name=os.getenv('S3_REGION', 'us-east-1'))

S3_BUCKET = os.getenv('S3_BUCKET_NAME', 'jazz-picker-pdfs')

@app.route('/api/pdf/<path:filename>')
def get_pdf_url(filename):
    """Generate presigned URL for PDF."""
    # Find variation in catalog
    variation = find_variation_by_filename(filename)
    if not variation:
        return jsonify({'error': 'Song not found'}), 404

    # Convert pdf_path to S3 key
    s3_key = catalog_path_to_s3_key(variation['pdf_path'])

    # Generate presigned URL (15 min expiry)
    try:
        url = s3_client.generate_presigned_url(
            'get_object',
            Params={
                'Bucket': S3_BUCKET,
                'Key': s3_key
            },
            ExpiresIn=900  # 15 minutes
        )

        return jsonify({
            'url': url,
            'expires_at': (datetime.utcnow() + timedelta(minutes=15)).isoformat(),
            'cached': True  # Cached in S3
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500
```

---

## Implementation Phases

### Phase 1: Fix PDF Viewer + S3 Setup (Week 1)

**Tasks:**

1. Fix PDF.js worker path in PDFViewer.tsx

   ```typescript
   pdfjs.GlobalWorkerOptions.workerSrc = "/pdf.worker.min.mjs";
   ```

2. Create S3 bucket and upload PDFs

   ```bash
   aws s3 mb s3://jazz-picker-pdfs
   # Upload existing PDFs from Dropbox
   ```

3. Update backend to use S3 presigned URLs

   - Add `boto3` to requirements.txt
   - Implement presigned URL generation
   - Test with existing catalog

4. Test PDF viewing on iPad
   - Verify worker loads correctly
   - Check PDF rendering performance
   - Test zoom/navigation

**Success Criteria:**

- PDFs load and render on iPad
- No 404 errors from worker
- Presigned URLs working

---

### Phase 2: Deploy to Production (Week 2)

**Tasks:**

1. Deploy backend to Fly.io

   ```bash
   flyctl launch --name jazz-picker-api
   flyctl secrets set AWS_ACCESS_KEY_ID=xxx
   flyctl deploy
   ```

2. Deploy frontend to Cloudflare Pages

   - Push to GitHub
   - Connect Cloudflare Pages
   - Set build command: `cd frontend && npm run build`

3. Configure CORS

   ```python
   CORS(app, resources={
       r"/api/*": {"origins": ["https://jazz-picker.pages.dev"]}
   })
   ```

4. Test end-to-end
   - iPad on WiFi
   - Search, filter, view PDFs
   - Performance check

**Success Criteria:**

- App accessible from iPad via public URL
- All features working
- Good performance (<2s load time)

---

### Phase 3: API Refinements (Week 3)

**Tasks:**

1. Implement slim API endpoints

   - `GET /api/songs` with pagination
   - `GET /api/songs/:title` for details
   - Update frontend to use new endpoints

2. Remove unused fields from responses

   - Strip server-side fields
   - Reduce payload size

3. Add server-side filtering

   - Filter by instrument/range in backend
   - Reduce client-side processing

4. Performance testing
   - Measure load times
   - Optimize slow queries

**Success Criteria:**

- Initial load <1s (vs current ~3s)
- API responses <50KB (vs current 5.4MB)
- Smooth scrolling on iPad

---

### Phase 4: Future Enhancements (Week 4+)

**Features:**

1. **Setlist Management**

   - Save collections of songs
   - Reorder songs
   - Export/share setlists
   - localStorage persistence

2. **PWA Support**

   - Add to Home Screen
   - Offline catalog browsing
   - Background PDF caching
   - Push notifications for new songs

3. **User Preferences**

   - Remember instrument/range filters
   - Favorite songs
   - Recently viewed
   - Dark mode

4. **Dropbox Sync Automation**
   - Watch for new PDFs
   - Auto-upload to S3
   - Rebuild catalog
   - Notify users

---

## Open Questions

### 1. S3 Bucket Access

**Option A: Public Bucket** (Simpler)

- Anyone with URL can access PDFs
- No authentication needed
- Presigned URLs still provide time-limited access

**Option B: Private Bucket** (More Secure)

- Require presigned URLs for all access
- Backend controls who sees what
- Slightly more complex

**Recommendation:** Start with **Option A** (public) since PDFs are not sensitive. Can switch to private later if needed.

---

### 2. CloudFront CDN

**Option A: Direct S3** (Simpler)

- Users download from S3 directly
- ~200ms latency from S3
- $0.09/GB transfer cost

**Option B: CloudFront CDN** (Faster)

- Edge caching, ~50ms latency
- First 100GB free, then $0.085/GB
- One-time setup complexity

**Recommendation:** Start **without CloudFront**. Add later if users report slow PDF loads.

---

### 3. Infrastructure as Code

**Option A: Manual Setup** (Fastest)

- Click through AWS/Cloudflare/Fly.io dashboards
- Document steps in this file
- Good for initial deployment

**Option B: Pulumi (Python)** (Better long-term)

- Define infrastructure in Python code
- Reproducible deployments
- Version control for infra

**Recommendation:** Start with **manual setup**. Consider Pulumi when:

- Adding team members
- Need to replicate to staging/prod environments
- Want infrastructure versioning

---

### 4. PDF Compilation Strategy

**Current Approach:**

- Erik compiles PDFs using LilyPond
- Saves to Dropbox
- Manual sync to S3 (for now)

**Future Automation Options:**

1. Dropbox webhook → Lambda → S3 sync
2. Scheduled job (daily) to check for new PDFs
3. GitHub Actions to compile + upload

**Recommendation:** Document Erik's workflow, automate in Phase 4.

---

## Next Steps

1. **Decide on open questions** above
2. **Fix PDF viewer** (1-line change)
3. **Set up S3 bucket** and upload PDFs
4. **Update backend** for presigned URLs
5. **Test on iPad**
6. **Deploy to production**

---

## Notes for Erik's Workflow

**Current Process (to document):**

1. Erik edits .ly files in `lilypond-data/Core/`
2. Runs LilyPond compilation (how? script?)
3. PDFs saved to Dropbox folders (Alto Voice, Baritone Voice, etc.)
4. catalog.json updated (automatically or manually?)

**Questions to ask Erik:**

- How do you trigger compilation? (script, manual?)
- How is catalog.json updated?
- Do you compile all variations or just changed ones?
- How often do new songs get added?

**Future automation goal:**

- Erik edits → auto-compile → auto-upload S3 → notify users
