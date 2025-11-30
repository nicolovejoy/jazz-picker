# Session Handoff - Nov 30, 2025 (Late Evening)

## Completed This Session

**Public Setlists & Shareable URLs:**
- Added `public` column to setlists table (shared with all logged-in users)
- Added `concert_key` column to setlist_items (override default key per song)
- Shareable URLs: `pianohouseproject.org?setlist={id}`
- "Copy Link" button in SetlistViewer header
- URL updates as you navigate (browser back button works)
- "Shared" badge on public setlists in SetlistManager

**Restored December Gig Setlist:**
- Recovered 16-song setlist from git history
- Inserted into Supabase with specific concert keys
- Fixed 5 song title mismatches with catalog

**Key Insight:**
Setlists store songs + concert keys, not PDFs. Each user sees charts rendered for their own instrument (transposition + clef). A bass player sees bass clef, a trumpet player sees Bb transposition, etc.

---

## Current State

**Live URLs:**
- Frontend: https://pianohouseproject.org
- Backend: https://jazz-picker.fly.dev

**What Works:**
- Supabase email/password auth
- 735 songs with dynamic PDF generation in any key
- Public setlists (viewable/editable by all logged-in users)
- Private setlists (owner only)
- Shareable setlist URLs with deep linking
- Concert key per setlist item (override default)
- Instrument label on PDFs (set in Settings)
- PDF download button
- All instruments (C, Bb, Eb transpositions + treble/bass clef)
- Search with infinite scroll
- iPad-optimized PDF viewer
- S3 caching (~7s new, <200ms cached)
- PWA support

**Key Components:**

| Component | Purpose |
|-----------|---------|
| `AuthGate.tsx` | Supabase sign in/up |
| `SetlistManager.tsx` | List/create/delete setlists, shows "Shared" badge |
| `SetlistViewer.tsx` | View setlist, remove songs, prefetch, copy link |
| `PDFViewer.tsx` | PDF display with download, setlist nav |
| `SettingsMenu.tsx` | Instrument selection, logout |

**Supabase Tables:**
- `setlists`: id, user_id, name, **public**, created_at, updated_at
- `setlist_items`: id, setlist_id, song_title, **concert_key**, position, notes, created_at
- RLS policies: users can CRUD own setlists + public setlists

---

## What's Left

**Phase 2 - Add Songs:**
- "Add to Setlist" button on song cards
- `AddToSetlistModal.tsx` - pick which setlist + key

**Phase 3 - Reorder:**
- Drag-to-reorder songs within setlist
- Use `@dnd-kit/core` or similar

**Future Ideas:**
- Toggle public/private on existing setlists
- Favorites (auditable, searchable)
- Random setlist generator
- Offline/cached PDFs for gigs

---

## Infrastructure

**Backend (Fly.io):**
- Flask API with LilyPond 2.25.30
- SQLite catalog from S3 on startup
- 2 workers, 120s timeout

**Frontend (Vercel):**
- Auto-deploys from GitHub main branch
- Domain: pianohouseproject.org

**Supabase:**
- Project: `qikzqyfrmrhabsfiuyag`
- Auth + PostgreSQL for setlists

**AWS (Terraform):**
- S3 bucket: `jazz-picker-pdfs`
- OIDC for GitHub Actions catalog updates

---

## Technical Debt

- [ ] No test suite
- [ ] Large JS bundle (~895KB) - could code-split
- [ ] Add songs to setlist from browse view
- [ ] Drag-to-reorder
- [ ] Admin panel to view registered users
