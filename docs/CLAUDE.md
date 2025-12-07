# CLAUDE.md

## Project Overview

Jazz Picker is an iPad music stand. ~730 songs from Eric's lilypond-lead-sheets repo.

| Component | Location | Notes |
|-----------|----------|-------|
| iOS App | `JazzPicker/` (SwiftUI) | Main focus |
| Backend | `app.py` (Flask on Fly.io) | PDF gen + setlists |
| Web | `frontend/` (React) | Simplified, no auth yet |

---

## Quick Start

```bash
# Backend
python3 app.py  # localhost:5001

# Frontend
cd frontend && npm run dev  # localhost:5173

# iOS
open JazzPicker/JazzPicker.xcodeproj
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

**Key patterns:**
- `@Observable` stores injected via environment
- Setlists sync to server (optimistic UI with rollback)
- Offline PDF caching in Documents/PDFCache/

---

## Backend API

```
GET  /api/v2/catalog              # All songs
POST /api/v2/generate             # Generate PDF
GET  /api/v2/setlists             # List setlists
POST /api/v2/setlists             # Create setlist
PUT  /api/v2/setlists/<id>        # Update setlist
DELETE /api/v2/setlists/<id>      # Delete setlist
```

---

## Transposition Model

| Term | Definition |
|------|------------|
| Concert Key | What audience hears (stored, shared) |
| Written Key | What player sees on chart |
| Transposition | Instrument offset: C, Bb, Eb |
| Octave Offset | Per-device adjustment |

---

## Current Work

See [ROADMAP.md](ROADMAP.md) for priorities.

**Next:** Firebase Auth (iOS) - Apple Sign-In

**Principle:** Work in small, clear increments. Each change should be independently deployable and testable.

---

## Related Docs

- [ROADMAP.md](ROADMAP.md) - Current priorities
- [INFRASTRUCTURE.md](INFRASTRUCTURE.md) - Services and scaling
- [FIREBASE_AUTH_PLAN.md](FIREBASE_AUTH_PLAN.md) - Auth implementation plan
