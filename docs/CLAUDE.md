# CLAUDE.md

## Project Overview

Jazz Picker is an iPad music stand. ~735 songs from Eric's lilypond-lead-sheets repo.

**Components:**
- iOS App: `JazzPicker/` (SwiftUI) - main focus
- Backend: `app.py` (Flask on Fly.io) - PDF gen, catalog
- Web: `frontend/` (React + Vite) - requires Firebase Auth

---

## Quick Start

```bash
python3 app.py              # Backend: localhost:5001
cd frontend && npm run dev  # Web: localhost:5173
open JazzPicker/JazzPicker.xcodeproj  # iOS
```

**Environment:** Web requires `frontend/.env.local` with Firebase config (see `.env.example`).

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

## Web App Structure

```
frontend/src/
├── contexts/   # AuthContext, UserProfileContext
├── components/ # UI components
├── services/   # api.ts, setlistService.ts, userProfileService.ts
└── types/      # TypeScript types
```

**Auth flow:** Sign in → Onboarding (if no profile) → Main app. Instrument synced via Firestore.

---

## Backend API

```
GET  /api/v2/catalog              # All songs
POST /api/v2/generate             # Generate PDF (auto-octave when instrument_label provided)
```

Setlist endpoints exist but moving to Firestore.

---

## Transposition Model

- **Concert Key**: What audience hears (stored, shared)
- **Written Key**: What player sees on chart
- **Transposition**: Instrument offset (C, Bb, Eb)
- **Octave Offset**: Per-song ±2, auto-calculated or manual

---

## Firestore Schema

```
users/{uid}
  - instrument: string
  - displayName: string
  - createdAt, updatedAt: timestamp

setlists/{setlistId}  # Phase 4
  - ownerId: string
  - title: string
  - songs: [{ songId, concertKey, octaveOffset }]
```

---

## Related Docs

- [ROADMAP.md](ROADMAP.md) - Priorities
- [INFRASTRUCTURE.md](INFRASTRUCTURE.md) - Services
