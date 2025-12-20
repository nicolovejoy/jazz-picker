# CLAUDE.md

## Project Overview

Jazz Picker is an iPad music stand app. 743 jazz lead sheets (742 from Eric's lilypond-lead-sheets + custom charts).

**Stack:**
- iOS App: `JazzPicker/` (SwiftUI) - primary client
- Web: `frontend/` (React + Vite) - gig-ready secondary client
- Backend: `app.py` (Flask on Fly.io) - PDF generation
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
├── Models/     # Song, Instrument, Setlist, UserProfile, Band
├── Views/      # Browse/, PDF/, Settings/, Setlists/, Auth/
├── Services/   # APIClient, SetlistStore, AuthStore, UserProfileStore, BandStore
└── Utils/      # JazzSlug
```

**Key Patterns:**
- `@Observable` stores via SwiftUI environment
- Optimistic UI with rollback on error
- Real-time Firestore listeners for setlists
- Offline PDF caching in Documents/PDFCache/
- Landscape: Forms/lists use `.frame(maxWidth: 600).frame(maxWidth: .infinity)`

**URL Schemes:**
- iOS: `jazzpicker://join/{code}` - implemented, needs testing
- Web: `https://jazzpicker.pianohouseproject.org/?join={code}`

## Backend API

```
GET  /api/v2/catalog    # Song list (title, default_key, composer, source)
POST /api/v2/generate   # PDF {song, concert_key, transposition, clef, instrument_label}
```

PDFs cached in S3. LilyPond generates on cache miss. Custom charts route to separate S3 bucket.

## Key Concepts

- **Concert Key**: What audience hears (stored in setlist items, includes 'm' suffix for minor)
- **Written Key**: What player sees (calculated from instrument transposition)
- **Preferred Key**: User's preferred key for a song (Firestore, sparse)
- **Octave Offset**: +/-2 adjustment when transposition lands too high/low
- **Source**: 'standard' (Eric's charts) or 'custom' (user-submitted)
- **Key Normalization**: iOS/Web strip 'm' suffix before API calls; backend determines minor from catalog

## Firestore Schema

```
users/{uid}
  - instrument, displayName, preferredKeys, groups[], lastUsedGroupId

groups/{groupId}
  - name, code (jazz slug like "bebop-monk-cool")

groups/{groupId}/members/{userId}
  - role: "admin" | "member", joinedAt

setlists/{id}
  - name, ownerId, groupId (required)
  - items: [{ id, songTitle, concertKey, position, octaveOffset, notes, isSetBreak }]
```

## Bands (Groups)

UI says "Band", Firestore uses `groups`. Every setlist belongs to a band.

- **Joining:** Enter jazz slug code or use invite link
- **Leaving:** Can't leave if sole admin
- **Deleting:** Must be only member, zero setlists

## Infrastructure

- **Fly.io** - Flask backend (~$10/mo)
- **AWS S3** - `jazz-picker-pdfs` (standard), `jazz-picker-custom-pdfs` (custom)
- **Vercel** - Web frontend (free)
- **Firebase** - Auth + Firestore (free tier)

## Secrets

Public repo - never commit secrets. GoogleService-Info.plist is gitignored.

**Fly.io** (`fly secrets list`): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
