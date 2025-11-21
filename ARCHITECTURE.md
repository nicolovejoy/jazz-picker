# Jazz Picker - Architecture & API Design

## Deployment Architecture (Decoupled Strategy)

### The "Contract" (S3)

We are moving to a fully decoupled architecture where the Backend/Frontend consumes data produced by an external process (Eric's repo).

```
┌─────────────────────────────┐      ┌──────────────────────────────┐
│   Eric's Repo               │      │   AWS S3                     │
│   (lilypond-lead-sheets)    │      │   (The Contract)             │
│                             │      │                              │
│   [ .ly Files ] ───────────┼─────►│   /pdfs/*.pdf                │
│        │                    │      │   /catalog.json              │
│   [ GitHub Action ] ────────┼─────►│                              │
└─────────────────────────────┘      └──────────────┬───────────────┘
                                                    │
                                                    │
┌─────────────────────────────┐      ┌──────────────▼───────────────┐
│   Nico's App                │      │   Nico's App                 │
│   (Backend - Flask)         │◄─────┤   (Frontend - React)         │
│                             │      │                              │
│   • Fetches catalog.json    │      │   • Fetches PDF links        │
│   • Serves API v2           │      │   • Displays UI              │
└─────────────────────────────┘      └──────────────────────────────┘
```

### Component Responsibilities

**Eric's Repo (Producer)**
- Source of truth for music (`.ly` files).
- Compiles PDFs via GitHub Actions.
- Generates `catalog.json`.
- Uploads everything to S3.

**Jazz Picker (Consumer)**
- **Backend**: Proxies/Caches `catalog.json` (or loads from S3). Provides search/filtering API.
- **Frontend**: Consumes API. Displays PDFs via S3 links.

---

## Implementation Status

### Phase 1: API Refinements (Current Focus)
**Goal**: Decouple Frontend from Backend file paths and enable S3 catalog loading.

- [x] **Backend**: Implement `GET /api/v2/songs` (Slim API).
- [x] **Backend**: Implement `GET /api/v2/songs/:id` (Details).
- [x] **Backend**: Support loading `catalog.json` from S3.
- [/] **Frontend**: Update to use API v2.
- [ ] **Frontend**: Remove dependency on `lilypond-data` file paths.

### Phase 2: "Cut the Cord" (Next)
**Goal**: Remove local `lilypond-data` dependency.

- [ ] Move `build_catalog.py` to Eric's repo.
- [ ] Setup GitHub Action in Eric's repo.
- [ ] Remove submodule from `jazz-picker`.
- [ ] Configure `jazz-picker` to strictly use S3 in production.

### Phase 3: Polish & Features
- [ ] Setlists.
- [ ] User Preferences.
- [ ] PWA / Offline Support.

---

## API Design (v2)

### Principles
- **Slim Client**: List endpoint returns minimal data (~50KB vs 5MB).
- **Opaque IDs**: Frontend uses IDs, not file paths.
- **Server-Side Filtering**: Backend handles logic.

### Endpoints

#### `GET /api/v2/songs`
Returns paginated list of songs with summary data (available keys/ranges).

#### `GET /api/v2/songs/:id`
Returns full details for a song, including all variations and S3 filenames.

---

## Legacy Notes (Preserved for Context)

### Old Phase 1: Fix PDF Viewer + S3 Setup
- [x] Fix PDF.js worker path.
- [x] Create S3 bucket.
- [x] Update backend for presigned URLs.

### Old Phase 2: Deploy to Production
- [ ] Deploy backend to Fly.io.
- [ ] Deploy frontend to Cloudflare Pages.

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

- Eric compiles PDFs using LilyPond
- Saves to Dropbox
- Manual sync to S3 (for now)

**Future Automation Options:**

1. Dropbox webhook → Lambda → S3 sync
2. Scheduled job (daily) to check for new PDFs
3. GitHub Actions to compile + upload

**Recommendation:** Document Eric's workflow, automate in Phase 4.

---

## Next Steps

1. **Decide on open questions** above
2. **Fix PDF viewer** (1-line change)
3. **Set up S3 bucket** and upload PDFs
4. **Update backend** for presigned URLs
5. **Test on iPad**
6. **Deploy to production**

---

## Notes for Eric's Workflow

**Current Process (to document):**

1. Erik edits .ly files in `lilypond-data/Core/`
2. Runs LilyPond compilation (how? script?)
3. PDFs saved to Dropbox folders (Alto Voice, Baritone Voice, etc.)
4. catalog.json updated (automatically or manually?)

**Questions to ask Eric:**

- How do you trigger compilation? (script, manual?)
- How is catalog.json updated?
- Do you compile all variations or just changed ones?
- How often do new songs get added?

**Future automation goal:**

- Eric edits → auto-compile → auto-upload S3 → notify users
