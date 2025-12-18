# CLAUDE.md

## Project Overview

Jazz Picker is an iPad music stand app. 799 jazz lead sheets from lilypond-lead-sheets repo.

**Stack:**
- iOS App: `JazzPicker/` (SwiftUI) — primary client
- Web: `frontend/` (React + Vite) — gig-ready secondary client
- Backend: `app.py` (Flask on Fly.io) — PDF generation only
- Firebase: Auth + Firestore (users, setlists)

**Live URLs:**
- Web: https://jazzpicker.pianohouseproject.org
- API: https://jazz-picker.fly.dev

## iOS Design

Stick to standard iOS patterns. Prefer swipe actions over context menus (faster). Use sheets instead of alerts for text input.

**Landscape:** Forms/lists use `.frame(maxWidth: 600).frame(maxWidth: .infinity)` for readability.

**Xcode 16+ auto-sync:** Project uses `PBXFileSystemSynchronizedRootGroup`. New Swift files added to `JazzPicker/JazzPicker/` are automatically included - no need to modify project.pbxproj.

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
├── Models/     # Song, Instrument, Setlist, UserProfile, Band, PDFNavigationContext
├── Views/      # Browse/, PDF/, Settings/, Setlists/, Auth/
├── Services/   # APIClient, SetlistStore, AuthStore, UserProfileStore, BandStore
└── Utils/      # JazzSlug
```

**Key Patterns:**
- `@Observable` stores via SwiftUI environment
- Optimistic UI with rollback on error
- Real-time Firestore listeners for setlists
- Offline PDF caching in Documents/PDFCache/
- Preferred keys synced to Firestore `users/{uid}.preferredKeys`

**URL Schemes:**
- iOS deep link: `jazzpicker://join/{code}` - WIP/untested (needs URL scheme in Xcode)
- Web join link: `https://jazzpicker.pianohouseproject.org/?join={code}`

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
  - instrument, displayName, preferredKeys, groups[], lastUsedGroupId
  - createdAt, updatedAt

groups/{groupId}
  - name, code (jazz slug like "bebop-monk-cool")
  - createdAt, updatedAt

groups/{groupId}/members/{userId}
  - role: "admin" | "member", joinedAt

setlists/{id}
  - name, ownerId, groupId (required)
  - createdAt, updatedAt
  - items: [{ id, songTitle, concertKey, position, octaveOffset, notes, isSetBreak }]

auditLog/{id}
  - groupId, action, actorId, targetId, timestamp, metadata
```

Security: Setlists filtered by group membership.

## Key Concepts

- **Concert Key**: What audience hears (stored in setlist items)
- **Written Key**: What player sees (calculated from instrument transposition)
- **Preferred Key**: User's preferred key for a song (Firestore, sparse - only non-defaults stored)
- **Octave Offset**: ±2 adjustment when transposition lands too high/low

## Infrastructure

- **Fly.io** — Flask backend, PDF generation (~$10/mo)
- **AWS S3** — PDF cache (~$1/mo)
- **Vercel** — Web frontend (free, auto-deploys on push)
- **Firebase** — Auth + Firestore (free tier)

## Bands (Groups)

UI says "Band", Firestore uses `groups`. Every setlist belongs to a band.

- **Joining:** Enter jazz slug code → added as member
- **Leaving:** Can't leave if sole admin
- **Deleting:** Must be only member, zero setlists
- **Invite flow:** Copy link with `?join={code}` (web) or `jazzpicker://join/{code}` (iOS, untested)

## Secrets

Public repo - never commit secrets. GoogleService-Info.plist is gitignored.

**Fly.io** (`fly secrets list`): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
