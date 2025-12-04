# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

!!! Eric is spelled with a C and not a K in this repository, always! !!!

Jazz Picker is an iPad music stand first and foremost. A deprecated web app version persists, for now.

**Primary Target: iPad Native App** - Must be gig-ready (used on stage at live performances).

| Component | Location | Status |
|-----------|----------|--------|
| Backend | Flask on Fly.io | Active |
| iOS App | `JazzPicker/` (SwiftUI) | Active |
| Web Frontend | `frontend/` (React) | Maintained, not priority |
| Legacy iOS | `frontend/ios/` (Capacitor) | Deprecated |
| Storage | AWS S3 + SQLite catalog | Active |

~735 songs from Eric's lilypond-lead-sheets repo (`neonscribe/lilypond-lead-sheets`). We consume his output, don't modify his workflow.

---

## iOS Development (SwiftUI)

```bash
open JazzPicker/JazzPicker.xcodeproj
# Select iPad simulator → Product → Run (⌘R)
```

**Structure:**
```
JazzPicker/JazzPicker/
├── App/        # JazzPickerApp.swift, ContentView.swift
├── Models/     # Song, Instrument, PDFNavigationContext
├── Views/      # Browse/, PDF/, Settings/, Components/
└── Services/   # APIClient, CatalogStore
```

**Bundle ID:** `com.pianohouseproject.jazzpicker-native`

**TestFlight:** Xcode → Any iOS Device (arm64) → Product → Archive → Distribute → App Store Connect

---

## Backend

```bash
pip install -r requirements.txt
python3 app.py  # localhost:5001

fly deploy      # Deploy to Fly.io
fly logs        # View logs
```

**API Endpoints:**
- `GET /api/v2/catalog` - Full catalog (~730 songs)
- `GET /api/v2/cached-keys?transposition=C&clef=treble` - All cached keys (bulk, for Browse pills)
- `GET /api/v2/songs/:title/cached` - Cached keys for a single song
- `POST /api/v2/generate` - Generate/fetch PDF (see below)

**Generate Request:**
```json
{
  "song": "502 Blues",
  "concert_key": "ef",
  "instrument_transposition": "Bb",
  "clef": "treble",
  "instrument_label": "Trumpet"
}
```

Returns S3 presigned URL + crop bounds for tight display.

---

## Transposition Model

Essential domain knowledge for this codebase.

| Term | Definition | Example |
|------|------------|---------|
| **Concert Key** | Key the audience hears. Stored in DB/API/S3. | "Concert Eb" |
| **Written Key** | What appears on the player's chart | Trumpet sees "F" |
| **Transposition** | Instrument category: C, Bb, Eb | Trumpet is "Bb" |

**The Math:** `Written Key = Concert Key + instrument interval`

```
Concert Eb:
├─ C instruments (piano):     Eb written
├─ Bb instruments (trumpet):  F written  (+M2)
└─ Eb instruments (alto sax): C written  (+M6)
```

**Instruments:** Piano, Guitar, Trumpet, Clarinet, Tenor Sax, Soprano Sax, Alto Sax, Bari Sax, Bass, Trombone

---

## S3 Cache

PDFs generated on-demand, cached in S3.

**Naming:** `{song-slug}-{concert-key}-{transposition}-{clef}.pdf`

Examples: `blue-bossa-ef-Bb-treble.pdf`, `autumn-leaves-g-C-bass.pdf`

---

## PDF Viewer

**Goal:** Immersive, distraction-free like forScore.

- Full bleed, no status bar
- Landscape: 2-up | Portrait: single page
- Auto-hide controls (1.5s) — appear on open/tap, NOT on swipe
- Swipe L/R for song navigation at page boundaries
- Swipe down or X to close
- Smart cropping via PyMuPDF

**Controls (top bar):** X (close), song title, key, menu (Change Key, Add to Setlist)

---

## LilyPond Integration

Eric's repo uses three-layer system:
1. **Core files** (`Core/*.ly`) - Music in reference key
2. **Include files** (`Include/*.ily`) - Transposition logic
3. **Wrapper files** (`Wrappers/*.ly`) - Variables + includes

Jazz Picker generates wrappers dynamically in `app.py:generate_wrapper_content()`.

LilyPond 2.25 runs in Fly.io Docker container. PDFs generate in ~2-5s.

---

## Infrastructure

**Terraform** (`infrastructure/`): S3 bucket, IAM user, GitHub OIDC for catalog auto-refresh.

**Auto-refresh:** When Eric pushes to lilypond-lead-sheets, GitHub Action rebuilds catalog.db → S3 → restarts Fly app.

**Manual refresh:**
```bash
python3 build_catalog.py
aws s3 cp catalog.db s3://jazz-picker-pdfs/catalog.db
fly apps restart jazz-picker
```

---

## Development Philosophy

- **Keep it simple** - No premature abstractions
- **Test in prod** - Limited users, fast iteration preferred
- **Ask before assuming** - Clarify when uncertain about state

---

## Known Issues

1. **Native rewrite active** - SwiftUI replacing Capacitor. See `SWIFT_ARCHITECTURE.md`
2. **No tests** - No test suite exists
3. **Symlinks** - Root has symlinks to Dropbox, don't modify
4. **LilyPond 2.25** - Dockerfile fetches from GitLab (apt only has 2.24)

---

## File Structure

```
jazz-picker/
├── app.py, db.py, crop_detector.py  # Backend
├── catalog.db                        # SQLite (from S3)
├── fly.toml, Dockerfile              # Fly.io deployment
├── infrastructure/                   # Terraform
├── JazzPicker/                       # Native SwiftUI app ← ACTIVE
├── frontend/                         # Web + deprecated Capacitor
└── docs/
    ├── CLAUDE.md                     # This file
    ├── HANDOFF.md                    # Session handoff notes
    ├── ROADMAP.md                    # Implementation phases + history
    ├── SETLIST_UX.md                 # Setlist UX spec (Phase 2)
    └── SWIFT_ARCHITECTURE.md         # iOS architecture details
```
