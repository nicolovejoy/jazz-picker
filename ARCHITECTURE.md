# Jazz Picker - Architecture

## System Overview

Decoupled architecture where Eric's repo produces PDFs/catalog, and Jazz Picker consumes them via S3.

```
┌─────────────────────────────┐      ┌──────────────────────────────┐
│   Eric's Repo               │      │   AWS S3 (The Contract)      │
│   (lilypond-lead-sheets)    │      │                              │
│                             │      │   • /pdfs/*.pdf              │
│   [ .ly Files ]             │─────►│   • /catalog.json            │
│   [ GitHub Action ]         │      │                              │
└─────────────────────────────┘      └──────────────┬───────────────┘
                                                    │
                                                    │
┌─────────────────────────────┐      ┌──────────────▼───────────────┐
│   Backend (Flask)           │      │   Frontend (React)           │
│                             │◄─────┤                              │
│   • Loads catalog from S3   │      │   • Infinite scroll          │
│   • API v2 (slim/paginated) │      │   • PDF viewer               │
│   • Presigned URLs          │      │   • Search/filter            │
└─────────────────────────────┘      └──────────────────────────────┘
```

## API v2

**Principles:**
- Slim responses (~50KB vs 5.4MB)
- Server-side filtering
- Infinite scroll with pre-fetch

**Endpoints:**
- `GET /api/v2/songs` - Paginated song list (summaries)
- `GET /api/v2/songs/:id` - Full song details with variations
- `GET /api/pdf/:filename` - Presigned S3 URL

## Current Status

**Working:**
- ✅ API v2 backend with S3 catalog loading
- ✅ Frontend with infinite scroll
- ✅ Search UX improvements (sticky search bar, clear button)
- ✅ Pre-fetch next page for smooth scrolling
- ✅ PDF viewing with landscape/portrait modes
- ✅ Server-side filtering by instrument/range

**Next Steps:**
- [ ] Deploy backend (Fly.io or similar)
- [ ] Deploy frontend (Cloudflare Pages or Vercel)
- [ ] Move `build_catalog.py` to Eric's repo
- [ ] Setup GitHub Action in Eric's repo for auto-compilation

**Future Features:**
- Setlists (save/reorder songs)
- User preferences (remember filters)
- PWA support (offline mode)
