# CLAUDE.md

## Project Overview

Jazz Picker is an iPad music stand. ~735 songs from Eric's lilypond-lead-sheets repo.

**Components:**

- iOS App: `JazzPicker/` (SwiftUI) - main focus
- Backend: `app.py` (Flask on Fly.io) - PDF gen, catalog
- Claude, update our firebaseFirestore dependency here
- Web: `frontend/` (React + Vite) - requires Firebase Auth

---

## Quick Start

note that we generally are still developing in production for the time being.

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
├── App/        # Entry point (JazzPickerApp), RootView, ContentView
├── Models/     # Song, Instrument, Setlist, UserProfile
├── Views/      # Browse/, PDF/, Settings/, Setlists/, Auth/
└── Services/   # APIClient, SetlistStore, PDFCacheService, AuthService, UserProfileService
```

**Patterns:**

- `@Observable` stores via environment
- Optimistic UI with rollback
- Offline PDF caching in Documents/PDFCache/

**Auth (Phase 5 - in progress):**

- Firebase Auth with Apple Sign-In
- Sign-in required to use app
- User profile (instrument) synced to Firestore `users/{uid}`
- Setlists still use Flask API with Firebase UID (Phase 6 will migrate to Firestore)

---

## Web App Structure

```
frontend/src/
├── contexts/   # AuthContext, UserProfileContext, SetlistContext
├── components/ # UI components
├── services/   # api.ts, setlistFirestoreService.ts, userProfileService.ts
└── types/      # TypeScript types
```

**Auth flow:** Sign in → Onboarding (if no profile) → Main app. Instrument synced via Firestore.

---

## Backend API

```
GET  /api/v2/catalog              # All songs
POST /api/v2/generate             # Generate PDF (auto-octave when instrument_label provided)
```

Setlist endpoints deprecated (Web uses Firestore, iOS still uses Flask).

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

setlists/{setlistId}
  - name: string
  - ownerId: string
  - items: [{ id, songTitle, concertKey, position, octaveOffset, notes }]
  - createdAt, updatedAt: timestamp
```

---

## Related Docs

- [ROADMAP.md](ROADMAP.md) - Priorities
- [INFRASTRUCTURE.md](INFRASTRUCTURE.md) - Services
