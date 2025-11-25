# Jazz Picker - Architecture

## System Overview

```
┌──────────────────────┐      ┌─────────────────────┐      ┌──────────────────────┐
│  Eric's Repo         │      │  AWS S3             │      │  Flask Backend       │
│  (lilypond sheets)   │─────►│  • PDFs (2GB)       │◄─────┤  (Fly.io)            │
│                      │      │  • catalog.json     │      │  • API v2            │
└──────────────────────┘      └─────────────────────┘      │  • Optional Auth     │
                                                            └──────────┬───────────┘
                                                                       │
                                                            ┌──────────▼───────────┐
                                                            │  React Frontend      │
                                                            │  (Local/TBD Deploy)  │
                                                            │  • PWA               │
                                                            │  • Song browser      │
                                                            │  • PDF viewer        │
                                                            └──────────────────────┘
```

---

## Current State (Nov 25, 2025)

### Backend (Flask)
- **Production:** https://jazz-picker.fly.dev (Fly.io)
- **API v2:** Paginated, slim responses (~50KB)
- **S3 Integration:** 2GB PDFs with 15min presigned URLs
- **Auth:** Optional basic auth (disabled by default)
- **Deployment:** Auto-scaling (0-1 machines), API-only (no templates)

### Frontend (React + TypeScript)
- **Branch:** `frontend/mcm-redesign` (latest)
- **Features:**
  - Two-filter system (Instrument + Singer Range)
  - Infinite scroll with smart pre-fetching
  - Smart navigation (auto-open single variations, Enter key shortcuts)
  - **iPad-optimized PDF viewer:**
    - Clean mode with auto-hide navigation (2s timeout)
    - Portrait: single page | Landscape: side-by-side
    - Pinch zoom (0.3x-5x), swipe gestures
    - Keyboard shortcuts (arrows, F for fullscreen, Esc)
  - PWA support (add to home screen)
  - Settings menu for global preferences
- **Tech Stack:** React 19, TypeScript, Tailwind CSS, React Query, react-pdf, Vite

---

## Data Model

### Catalog Structure (catalog.json)
```json
{
  "metadata": {
    "total_songs": 735,
    "total_files": 4366,
    "generated": "2025-11-24T..."
  },
  "songs": {
    "All of Me": {
      "title": "All of Me",
      "core_files": ["All of Me.ily"],  // Usually 1 file (729/735 songs)
                                         // 6 songs have 2: alternative keys,
                                         // guitar solos, or bass lines
      "variations": [
        {
          "filename": "All of Me - Ly - C Standard.ly",
          "display_name": "All of Me Standard Key",
          "key": "c",
          "instrument": "Treble",
          "variation_type": "Standard (Concert)",
          "pdf_path": "../Standard/All of Me - Ly - C Standard"
        }
      ]
    }
  }
}
```

### Filtering Logic
- **Instruments:** C (Standard Concert), Bb, Eb, Bass
- **Voice Ranges:** Alto/Mezzo/Soprano, Baritone/Tenor/Bass, Standard
- Voice variations excluded from instrument filters (fixed Nov 22)
- Accurate variation counts per filter

---

## API Endpoints

### Songs
- `GET /api/v2/songs` - Paginated song list (limit, offset, q, instrument, range)
- `GET /api/v2/songs/:title` - Song details with all variations

### PDFs
- `GET /pdf/:filename` - S3 presigned URL (15min expiry)

### Health
- `GET /health` - Health check for deployment platforms

---

## Deployment

### Backend (Fly.io)
```bash
fly deploy                           # Deploy latest
fly secrets set REQUIRE_AUTH=true   # Enable auth (optional)
fly logs                             # View logs
```

**Environment:**
- `USE_S3=true`
- `S3_BUCKET_NAME=jazz-picker-pdfs`
- `S3_REGION=us-east-1`
- `AWS_ACCESS_KEY_ID` (secret)
- `AWS_SECRET_ACCESS_KEY` (secret)

### Frontend (Not Yet Deployed)
**Options:**
- Cloudflare Pages (recommended)
- Vercel
- Netlify

**Build:**
```bash
cd frontend && npm run build
# Output: frontend/dist
# Env: VITE_API_URL=https://jazz-picker.fly.dev
```

---

## Development Workflow

### Local Development

**Frontend (default setup):**
```bash
cd frontend && npm run dev  # Port 5173
# Uses deployed backend via Vite proxy (jazz-picker.fly.dev)
```

**Backend Development (optional):**
```bash
# 1. Run backend locally
python3 app.py              # Port 5001

# 2. Update vite.config.ts proxy target to 'http://localhost:5001'
# 3. Run frontend
cd frontend && npm run dev
```

### Git Workflow
```bash
git checkout main
git pull
git checkout -b feature/name
# ... make changes ...
git push
# Merge when ready
```

### Syncing PDFs to S3 (Eric's workflow)
```bash
python3 build_catalog.py    # Update catalog
./sync_pdfs_to_s3.sh        # Sync to S3
```

---

## Next Steps

> 💡 **See [Unified Roadmap](file:///Users/nico/.gemini/antigravity/brain/bbeab143-d7b7-47ef-ad5c-9dad8a3aae4f/unified_roadmap.md) for complete 3-month plan with dependencies and agent assignments**

### This Week: Production Deploy (9 hours)

**Backend Improvements** (Backend Agent)
- Error handling & validation (30 min)
- API response caching with ETags (30 min)

**Frontend Deployment** (DevOps Agent)  
- Deploy to Cloudflare Pages (4 hours)
- Add monitoring: Sentry, Fly.io alerts, UptimeRobot (4 hours)

**Outcome:** Live production app at custom domain

### Weeks 2-3: Core Features (4-5 days)

**iPad Optimization** (Frontend Agent)
- Increase touch targets for better tap accuracy
- Landscape-optimized layouts
- Gesture refinements and palm rejection

**Setlist Feature** (Setlist Agent)
- LocalStorage-based setlists (10 hours)
- Create/edit/delete setlists
- Add songs to setlists
- Play through setlist in PDF viewer

### Month 2: Performance & PWA

**Service Worker** (Frontend Agent)
- Offline PDF caching
- Runtime caching strategy
- Precaching of static assets

**React Query Optimization** (Frontend Agent)
- Search debouncing
- Virtual scrolling for large lists
- Optimized prefetching

### Month 3: Database (Optional)

**Only if users request multi-user/sync features:**
- Fly Postgres setup (DevOps Agent)
- Data model enhancements with stable IDs (Backend Agent)
- Flask-Login authentication (Backend Agent)
- Migrate setlists from LocalStorage to DB (Setlist Agent)

---

## Strategic Decisions

**Setlists:** Start with LocalStorage (fast, no backend changes), migrate to DB only if users demand cross-device sync

**Service Worker:** Hybrid caching (last 50 PDFs + "pin to offline" feature)

**Deployment:** Cloudflare Pages (free, fast CDN, auto-deploys from Git)

**Database:** SQLite on Fly volume ($0) or Postgres ($15/mo) - decide based on scale needs

---

## Cost Estimation

**Fly.io Backend:** $0-5/month (within free tier)
**S3 Storage:** ~$0.05/month (2GB)
**Frontend:** $0 (static hosting free tier)

**Total: ~$1-5/month**
