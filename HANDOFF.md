# Session Handoff - Nov 29, 2025

## Completed This Session

**Auto-Refresh Catalog (GitHub Actions + OIDC):**
- Added OIDC identity provider to AWS (Terraform) - GitHub Actions can now assume IAM roles without long-lived credentials
- Created `jazz-picker-catalog-updater` IAM role scoped to only upload `catalog.db` to S3
- Workflow in Eric's repo: on push to Wrappers/ or Core/, rebuilds catalog, uploads to S3, restarts Fly app
- Waiting on Eric to add `FLY_API_TOKEN` secret to his repo

**Password Protection:**
- Added `PasswordGate.tsx` component - shown before welcome screen
- Shared password: `vashonista!`
- Auth state persisted in localStorage
- Logout button added to Settings menu

**Setlist Feature:**
- Hardcoded gig setlist with 16 songs
- Green highlight for cached songs (fetched on mount)
- Swipe L/R navigation between songs when viewing PDFs
- Position indicator ("3 / 16") in bottom-right of PDF viewer

**Browser Compatibility:**
- Added `URL.parse()` polyfill for Safari 17 (pdfjs-dist 5.x requires it)
- Alternative: downgrade to react-pdf 9.x / pdfjs-dist 4.x

**PWA Fixes:**
- Added safe area padding to PDF viewer for iOS notch/status bar

**Setlist Song Title Fixes:**
- "The In Crowd" (not "The 'In' Crowd")
- "I Fall In Love Too Easily" (capital I in In)
- "Alright Okay You Win" (no commas)
- "Is You Is or Is You Ain't (Ma' Baby)"
- "C'est Si Bon French" (not English)

---

## Previous Session (Nov 30, 2025)

**SQLite Migration:**
- Backend now uses `catalog.db` instead of `catalog.json`
- Created `db.py` module for all database access
- `catalog.db` downloaded from S3 on startup

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

---

## Current State

**Live URLs:**
- Frontend: https://pianohouseproject.org (also: frontend-phi-khaki-43.vercel.app)
- Backend: https://jazz-picker.fly.dev

**What Works:**
- Password-protected access
- 735 songs with dynamic PDF generation
- All instrument filters (C, Bb, Eb, Bass)
- Search with infinite scroll
- iPad-optimized PDF viewer with safe area support
- S3 caching of generated PDFs (~7s new, <200ms cached)
- Hardcoded gig setlist with swipe navigation
- PWA support (Add to Home Screen on iPad)

**Authentication:**
- Frontend password gate (Phase 1 complete)
- Backend basic auth available but not enabled

**State Management:**
- React Query for server state (songs, cached keys)
- React useState for UI state
- LocalStorage for: instrument preference, auth state

---

## Key Components

| Component | Purpose |
|-----------|---------|
| `PasswordGate.tsx` | Password prompt before app access |
| `WelcomeScreen.tsx` | Instrument selection |
| `Setlist.tsx` | Hardcoded gig setlist with cached status |
| `PDFViewer.tsx` | PDF display with setlist navigation |
| `SettingsMenu.tsx` | Preferences + logout |

---

## Infrastructure

**Backend (Fly.io):**
- Flask API with LilyPond 2.25.30
- SQLite catalog downloaded from S3 on startup
- 2 workers, 120s timeout

**Frontend (Vercel):**
- Auto-deploys from GitHub main branch
- Custom domain: pianohouseproject.org

**AWS (Terraform-managed):**
- S3 bucket: `jazz-picker-pdfs`
- Contains: `catalog.db`, `generated/` folder for cached PDFs
- OIDC provider for GitHub Actions (keyless auth)
- IAM role `jazz-picker-catalog-updater` for catalog updates

---

# Future Work

## Phase 2: User Accounts
- Enables per-user setlists and preferences
- Options: Supabase Auth, Clerk, Auth0
- Would replace current shared password

## Dynamic Setlists
- Currently hardcoded in `Setlist.tsx`
- Future: editable setlists, drag to reorder
- Requires user accounts for persistence

## Auto-Refresh Catalog ✅
Implemented via GitHub Action in Eric's `neonscribe/lilypond-lead-sheets` repo:
- On push to `Wrappers/` or `Core/`: rebuilds catalog, uploads to S3, restarts Fly app
- Uses OIDC for AWS auth (no long-lived credentials)
- Manual fallback: `python3 build_catalog.py && aws s3 cp catalog.db s3://jazz-picker-pdfs/ && fly apps restart jazz-picker`

## Technical Debt
- [ ] No test suite
- [ ] Large JS bundle (~690KB) - could code-split
- [ ] Cleanup unused catalog.json from S3
- [ ] Remove old pre-built PDF folders from S3
