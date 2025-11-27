# Session Handoff - Nov 27, 2025

## Completed This Session

**UI Improvements:**
- Key buttons now show proper notation (B♭ instead of bf,)
- Bass clef charts color-coded green with hover tooltip
- Removed Singer Range filter (Eric-approved simplification)

**Documentation:**
- Deleted outdated `ARCHITECTURE.md`
- Created `LILYPOND_PLAN.md` - research on dynamic chart generation
- Created `SCHEMA_PLAN.md` - SQLite database schema for Phase 1 & 2

**Planning:**
- Researched LilyPond Docker integration options
- Designed schema for songs, variations, singers, generated_charts, users, setlists
- Decision: SQLite on Fly.io volume, plan for user accounts but execute LilyPond first

## Current State

**Live URLs:**
- Frontend: https://frontend-phi-khaki-43.vercel.app/
- Backend: https://jazz-picker.fly.dev

**Features Working:**
- Instrument filter (C, Bb, Eb, Bass)
- Search with infinite scroll
- iPad-optimized PDF viewer
- Key display with ♭/♯ symbols

## Next Steps (Phase 1: LilyPond)

See `SCHEMA_PLAN.md` for full details.

1. Enhance `build_catalog.py` for SQLite + singer extraction
2. Setup Fly.io volume for SQLite persistence
3. Add LilyPond to Docker image
4. Create `/api/v2/generate` endpoint
5. Update frontend: cached keys vs generatable

## Key Decisions Made

- **SQLite on Fly.io** (not Postgres) for data store
- **Singer extraction at build time** from wrapper `instrument` field
- **Range stored on songs**, computed per variation by transposition
- **User accounts planned** but not blocking LilyPond work
- **Admin approval flow** for new users (prospective_user → user)

## Open Questions for Eric

1. `variation_type` decomposition - split into instrument/clef/preset_label?
2. Preferred singer range format for users?
3. Core file timestamp - git history or file mtime?

---

**Date:** Nov 27, 2025
