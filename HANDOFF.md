# Session Handoff - Nov 30, 2025

## Completed This Session

**SQLite Migration:**
- Backend now uses `catalog.db` instead of `catalog.json`
- Created `db.py` module for all database access
- `catalog.db` downloaded from S3 on startup
- Uploaded current catalog.db to S3

**Frontend Redesign:**
- New song card design: default key + cached keys as pills
- Green border indicates songs with any cached version
- Plus button opens GenerateModal for custom key selection
- Auto-refresh: generating a new key immediately updates the card

**Debug Badge:**
- PDF viewer shows info badge (bottom-left)
- Displays: cached/generated status, generation time, song/key info
- Tap to expand for full details

**Domain:**
- Connected `pianohouseproject.org` to Vercel frontend

## Current State

**Live URLs:**
- Frontend: https://pianohouseproject.org (also: frontend-phi-khaki-43.vercel.app)
- Backend: https://jazz-picker.fly.dev

**What Works:**
- 735 songs with dynamic PDF generation
- All instrument filters (C, Bb, Eb, Bass)
- Search with infinite scroll
- iPad-optimized PDF viewer
- S3 caching of generated PDFs (~7s new, <200ms cached)
- Debug badge showing cache status

**State Management:**
- React Query for server state (songs, cached keys)
- React useState for UI state
- LocalStorage for instrument preference

## Key Files Changed

- `db.py` - NEW: SQLite database access layer
- `app.py` - Uses SQLite via db module
- `Dockerfile.prod` - Copies db.py, downloads catalog.db from S3
- `frontend/src/components/SongListItem.tsx` - New card design
- `frontend/src/components/PDFViewer.tsx` - Debug badge
- `frontend/src/components/GenerateModal.tsx` - Cache invalidation on generate

## Infrastructure

**Backend (Fly.io):**
- Flask API with LilyPond 2.25.30
- SQLite catalog downloaded from S3 on startup
- 2 workers, 120s timeout

**AWS (Terraform-managed):**
- S3 bucket: `jazz-picker-pdfs`
- Contains: `catalog.db`, `generated/` folder for cached PDFs

---

# Future Work

## Auth Implementation

**Decision needed:** Supabase Auth vs Vercel Auth vs simple password

### Phase 1: Simple Password Gate
- Frontend password prompt (stored in localStorage)
- Quick to implement, good enough for friends/family access

### Phase 2: User Accounts
- Enables per-user setlists and preferences
- Options: Supabase Auth, Clerk, Auth0

### Phase 3: Roles (if needed)
- Admin: cache invalidation, stats
- User: normal access

## Setlists Feature

**Concept:** Users create named lists of songs for gigs/practice.

**Requires:**
- User accounts (for persistence)
- New database tables: `setlists`, `setlist_songs`
- UI: Create/edit setlist, drag to reorder, "practice mode" view
- Optional: Pre-generate all PDFs in a setlist for offline use

**State Management:**
- Add Zustand when setlists need client-side state
- React Query continues for server data

## Auto-Refresh Catalog

When Eric updates charts in his repo:

**Option A: GitHub Action (recommended)**
- Add workflow to Eric's lilypond-lead-sheets repo
- On push: rebuild catalog.db, upload to S3, restart Fly app
- Secrets needed: AWS keys, FLY_API_TOKEN

**Option B: Manual**
- Run `build_catalog.py` locally
- Upload: `aws s3 cp catalog.db s3://jazz-picker-pdfs/`
- Deploy: `fly deploy`

## Technical Debt

- [ ] No test suite
- [ ] Large JS bundle (684KB) - could code-split
- [ ] Cleanup unused catalog.json from S3
- [ ] Remove old pre-built PDF folders from S3 (Standard/, Alto-Voice/, etc.)
