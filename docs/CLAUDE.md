# CLAUDE.md

## Project Overview

Jazz Picker is an iPad music stand app. ~735 jazz lead sheets from lilypond-lead-sheets repo.

**Stack:**
- iOS App: `JazzPicker/` (SwiftUI) — primary client
- Web: `frontend/` (React + Vite) — gig-ready secondary client
- Backend: `app.py` (Flask on Fly.io) — PDF generation only
- Firebase: Auth + Firestore (users, setlists)

**Live URLs:**
- Web: https://jazzpicker.pianohouseproject.org
- API: https://jazz-picker.fly.dev

## Quick Start

```bash
python3 app.py              # Backend: localhost:5001
cd frontend && npm run dev  # Web: localhost:5173
open JazzPicker/JazzPicker.xcodeproj  # iOS
```

## iOS App Structure

```
JazzPicker/JazzPicker/
├── App/        # JazzPickerApp, ContentView
├── Models/     # Song, Instrument, Setlist, UserProfile, PDFNavigationContext
├── Views/      # Browse/, PDF/, Settings/, Setlists/, Auth/
└── Services/   # APIClient, SetlistStore, AuthStore, UserProfileStore, CachedKeysStore
```

**Key Patterns:**
- `@Observable` stores via SwiftUI environment
- Optimistic UI with rollback on error
- Real-time Firestore listeners for setlists
- Offline PDF caching in Documents/PDFCache/
- Preferred keys synced to Firestore `users/{uid}.preferredKeys`

## Backend API

```
GET  /api/v2/catalog    # Song list (title, default_key, composer, note range)
POST /api/v2/generate   # PDF {song, concert_key, transposition, clef, instrument_label}
```

PDFs cached in S3. LilyPond generates on cache miss.

## Catalog Build

```bash
python build_catalog.py --ranges-file lilypond-data/Wrappers/range-data.txt
```

GitHub workflow auto-rebuilds when Eric pushes to his repo.

## Firestore Schema

```
users/{uid}
  - instrument, displayName, preferredKeys, createdAt, updatedAt

setlists/{id}
  - name, ownerId, createdAt, updatedAt
  - items: [{ id, songTitle, concertKey, position, octaveOffset, notes }]
```

Security: All authenticated users share setlists (2-person band). See GROUPS.md for multi-band design.

## Key Concepts

- **Concert Key**: What audience hears (stored in setlist items)
- **Written Key**: What player sees (calculated from instrument transposition)
- **Preferred Key**: User's preferred key for a song (Firestore, sparse - only non-defaults stored)
- **Octave Offset**: ±2 adjustment when transposition lands too high/low

## Secrets

Public repo - never commit secrets. GoogleService-Info.plist is gitignored.
