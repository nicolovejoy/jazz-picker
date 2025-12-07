# CLAUDE.md

## Project Overview

Jazz Picker is an iPad music stand. ~735 songs from Eric's lilypond-lead-sheets repo.

**Components:**
- iOS App: `JazzPicker/` (SwiftUI) - main focus
- Backend: `app.py` (Flask on Fly.io) - PDF gen + setlists
- Web: `frontend/` (React) - no auth

---

## Quick Start

```bash
python3 app.py              # Backend: localhost:5001
cd frontend && npm run dev  # Web: localhost:5173
open JazzPicker/JazzPicker.xcodeproj  # iOS
```

---

## iOS App Structure

```
JazzPicker/JazzPicker/
├── App/        # Entry point, tabs
├── Models/     # Song, Instrument, Setlist
├── Views/      # Browse/, PDF/, Settings/, Setlists/
└── Services/   # APIClient, SetlistStore, PDFCacheService
```

**Patterns:**
- `@Observable` stores via environment
- Optimistic UI with rollback
- Offline PDF caching in Documents/PDFCache/

---

## Backend API

```
GET  /api/v2/catalog              # All songs
POST /api/v2/generate             # Generate PDF (accepts octave_offset)
GET  /api/v2/setlists             # List setlists
POST /api/v2/setlists             # Create setlist
PUT  /api/v2/setlists/<id>        # Update setlist
DELETE /api/v2/setlists/<id>      # Delete setlist
```

---

## Transposition Model

- **Concert Key**: What audience hears (stored, shared)
- **Written Key**: What player sees on chart
- **Transposition**: Instrument offset (C, Bb, Eb)
- **Octave Offset**: Per-song adjustment (±2), saved in setlist items

---

## Related Docs

- [ROADMAP.md](ROADMAP.md) - Priorities
- [INFRASTRUCTURE.md](INFRASTRUCTURE.md) - Services
- [FIREBASE_AUTH_PLAN.md](FIREBASE_AUTH_PLAN.md) - Auth (backlog)
