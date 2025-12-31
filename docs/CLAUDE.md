# CLAUDE.md

## Project Overview

Jazz Picker is an iPad music stand app. 750+ jazz lead sheets.

**Stack:**
- iOS App: `JazzPicker/` (SwiftUI, iOS 17+) - primary client
- Web: `frontend/` (React + Vite) - secondary client
- Backend: `app.py` (Flask on Fly.io) - PDF generation
- Firebase: Auth + Firestore

**URLs:**
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
├── Services/   # APIClient, *Store.swift, *FirestoreService.swift
├── Resources/  # BuildHistory.json
└── Utils/      # JazzSlug
```

**BuildHistory.json**: User-facing release notes shown in About page. Add entry for each TestFlight build with build number, date, and notes describing new features. Newest first.

**Patterns:**
- `ObservableObject` stores with `@Published`, injected via `.environmentObject()`
- Real-time Firestore listeners
- Offline PDF caching in Documents/PDFCache/
- Landscape forms: `.frame(maxWidth: 600).frame(maxWidth: .infinity)`
- PDF viewer disables idle timer (no sleep during gigs)
- Metronome: `MetronomeEngine` (AVAudioEngine + haptics), `MetronomeStore`, `MetronomeSettings` (UserDefaults). Overlay auto-hides with controls after 5s. Visual beat pulse via `BeatPulseOverlay`. Sounds: wood block (default), cowbell, hi-hat, click, silent.

## Backend API

```
GET  /api/v2/catalog    # Song list with includeVersion for cache invalidation
POST /api/v2/generate   # PDF {song, concert_key, transposition, clef, instrument_label, octave_offset}
```

PDFs cached in S3 with `includeVersion` metadata. Regenerates on cache miss or version mismatch.

## Key Concepts

- **Concert Key**: What audience hears (stored, includes 'm' for minor)
- **Written Key**: What player sees (calculated from transposition)
- **Octave Offset**: ±2 adjustment when transposition lands too high/low. Priority: setlist item > Groove Sync leader > user preference > auto-calc > 0
- **Source**: 'standard' or 'custom'
- **Ambitus**: Note range stored as MIDI (lowNoteMidi, highNoteMidi). Displayed in transpose modal via `AmbitusView` (client-rendered staff).
- **Multi-part scores**: Songs with `scoreId` and `partName` are grouped in iOS browse list (expandable rows).
- **Tempo**: Extracted from LilyPond `\tempo` and `\time` commands. Fields: `tempo_style` ("Medium Swing"), `tempo_source` ("Billie Holiday 1937"), `tempo_bpm`, `tempo_note_value` (4=quarter), `time_signature` ("4/4").

## Firestore Schema

```
users/{uid}
  - instrument, displayName, preferredKeys, preferredOctaveOffsets, groups[], lastUsedGroupId

groups/{groupId}
  - name, code (jazz slug)

groups/{groupId}/members/{userId}
  - role: "admin" | "member", joinedAt

groups/{groupId}/session/current   # Groove Sync
  - leaderId, leaderName, startedAt, lastActivityAt
  - currentSong: { title, concertKey, source, octaveOffset? }

setlists/{id}
  - name, ownerId, groupId
  - items: [{ id, songTitle, concertKey, position, octaveOffset, notes, isSetBreak }]
```

## Bands

UI says "Band", Firestore uses `groups`. Every setlist belongs to a band.

**URL Schemes:**
- iOS: `jazzpicker://join/{code}`, `jazzpicker://setlist/{id}`
- Web: `/join/{code}`, `/setlist/{id}`, `/song/{slug}?key=g&octave=1` (React Router)

## Groove Sync

Real-time chart sharing. iOS can lead or follow; web can follow only.

**Files:**
- iOS: `GrooveSyncService.swift`, `GrooveSyncStore.swift`, `GrooveSyncModal.swift`
- Web: `grooveSyncService.ts`, `GrooveSyncContext.tsx`, `GrooveSyncFollower.tsx`

See `docs/GROOVE_SYNC.md` for details.

## Infrastructure

- **Fly.io** - Flask backend
- **AWS S3** - `jazz-picker-pdfs`, `jazz-picker-custom-pdfs`
- **Vercel** - Web frontend (auto-deploys from GitHub on push to main)
- **Firebase** - Auth + Firestore

Never commit secrets. GoogleService-Info.plist is gitignored.

## Web Deploy & Test

Vercel auto-deploys when you push to main. After deploy, test:

1. Direct link: `/song/all-the-things-you-are` - should load song
2. Direct link with key: `/song/autumn-leaves?key=g` - should load in G
3. Browse → click song → URL updates to `/song/...`
4. Change key → URL adds `?key=...`
5. Browser back → closes PDF, returns to browse

SPA routing configured in root `vercel.json` (rewrites all paths to index.html).

## Tools

`tools/musicxml_to_lilypond.py` - MusicXML → multi-part LilyPond. Chord symbols, repeat expansion, pickup detection.

## Docs

- `ROADMAP.md` - Priority queue
- `DEPLOY.md` - Deploy workflow
- `CUSTOM_CHARTS.md` - Manual chart creation
- `MULTI_PART_SCORES.md` - MusicXML converter usage
- `GROOVE_SYNC.md` - Real-time chart sharing spec
