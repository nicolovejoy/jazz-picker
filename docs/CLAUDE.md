# CLAUDE.md

## Project Overview

Jazz Picker is an iPad music stand. ~735 songs from Eric's lilypond-lead-sheets repo.

**Components:**

- iOS App: `JazzPicker/` (SwiftUI) — primary client
- Backend: `app.py` (Flask on Fly.io) — PDF generation, catalog API
- Web: `frontend/` (React + Vite) — secondary client
- Firebase: Auth + Firestore (setlists, user profiles)

**Note:** Developing in production for now.

---

## Quick Start

```bash
python3 app.py              # Backend: localhost:5001
cd frontend && npm run dev  # Web: localhost:5173
open JazzPicker/JazzPicker.xcodeproj  # iOS
```

Web requires `frontend/.env.local` with Firebase config (see `.env.example`).

---

## iOS App Structure

```
JazzPicker/JazzPicker/
├── App/        # JazzPickerApp, RootView, ContentView
├── Models/     # Song, Instrument, Setlist, UserProfile
├── Views/      # Browse/, PDF/, Settings/, Setlists/, Auth/
└── Services/   # APIClient, SetlistStore, SetlistFirestoreService, AuthStore, UserProfileStore
```

**Patterns:**

- `@Observable` stores via SwiftUI environment
- Optimistic UI with rollback
- Offline PDF caching in Documents/PDFCache/
- Real-time Firestore listeners for setlists
- DO NOT expose any secrets in the codebase, as it's a public repo on github

---

## Backend API

```
GET  /api/v2/catalog    # All songs
POST /api/v2/generate   # Generate PDF {title, key, transposition, clef, instrument_label}
```

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
  - instrument, displayName, createdAt, updatedAt

setlists/{setlistId}
  - name, ownerId, createdAt, updatedAt
  - items: [{ id, songTitle, concertKey, position, octaveOffset, notes }]
```

---

## Related Docs

- [ROADMAP.md](ROADMAP.md) — Current priorities
- [INFRASTRUCTURE.md](INFRASTRUCTURE.md) — Services & deployment
- [ARCHITECTURE.md](ARCHITECTURE.md) — Data flows
