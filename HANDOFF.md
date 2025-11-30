# Session Handoff - Nov 30, 2025 (Evening)

## Completed This Session

**Editable Setlists (Phase 1):**
- Replaced hardcoded setlist with Supabase-backed setlists
- `SetlistManager.tsx`: view, create, delete user setlists
- `SetlistViewer.tsx`: view songs, remove items, prefetch PDFs
- Supabase service layer (`setlistService.ts`) + React Query hooks
- Fixed RLS policy to allow inserts (needed `WITH CHECK`)

**PDF Download Button:**
- Download icon in PDF viewer header
- Generates filename from song title and key (e.g., "Blue Bossa - C.pdf")

**Instrument Label Feature:**
- Settings → "Instrument Label" (e.g., "Trumpet in Bb")
- Appears in PDF subtitle when generating
- Cached separately in S3: `{song}-{key}-{clef}-{instrument-slug}.pdf`
- Backend `/api/v2/generate` accepts optional `instrument` param

**Supabase Auth Fix:**
- Updated Site URL to `https://pianohouseproject.org` (was localhost)
- Email confirmation links now work correctly

---

## Current State

**Live URLs:**
- Frontend: https://pianohouseproject.org
- Backend: https://jazz-picker.fly.dev

**What Works:**
- Supabase email/password auth
- 735 songs with dynamic PDF generation in any key
- Editable setlists (create, delete, remove songs)
- Instrument label on PDFs (set in Settings)
- PDF download button
- All instrument filters (C, Bb, Eb, Bass)
- Search with infinite scroll
- iPad-optimized PDF viewer
- S3 caching (~7s new, <200ms cached)
- PWA support

**Key Components:**

| Component | Purpose |
|-----------|---------|
| `AuthGate.tsx` | Supabase sign in/up |
| `SetlistManager.tsx` | List/create/delete setlists |
| `SetlistViewer.tsx` | View setlist, remove songs, prefetch |
| `PDFViewer.tsx` | PDF display with download, setlist nav |
| `SettingsMenu.tsx` | Instrument label, logout |

**Supabase Tables:**
- `setlists`: id, user_id, name, created_at, updated_at
- `setlist_items`: id, setlist_id, song_title, variation_filename, position, notes, created_at
- RLS policies: users can only CRUD their own setlists/items

---

## What's Left for Editable Setlists

**Phase 2 - Add Songs:**
- "Add to Setlist" button on song cards
- `AddToSetlistModal.tsx` - pick which setlist

**Phase 3 - Reorder:**
- Drag-to-reorder songs within setlist
- Use `@dnd-kit/core` or similar

**Phase 4 - Sharing:**
- Share setlist with other users
- `setlist_shares` table (setlist_id, shared_with_user_id, permission)

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

## Technical Debt / Future Work

- [ ] No test suite
- [ ] Large JS bundle (~890KB) - could code-split
- [ ] Review catalog/filename architecture for extensibility
- [ ] Add songs to setlist from browse view (Phase 2)
- [ ] Drag-to-reorder (Phase 3)
- [ ] Setlist sharing (Phase 4)
- [ ] Admin panel to view registered users
