# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

Jazz Picker is an iPad music stand. ~730 songs from Eric's lilypond-lead-sheets repo.

| Component | Location                   | Status     |
| --------- | -------------------------- | ---------- |
| iOS App   | `JazzPicker/` (SwiftUI)    | Active     |
| Backend   | `app.py` (Flask on Fly.io) | Active     |
| Storage   | AWS S3 + SQLite catalog    | Active     |
| Web       | `frontend/` (React)        | Maintained |

---

## iOS App

```bash
open JazzPicker/JazzPicker.xcodeproj
# iPad testing → ⌘R
```

**Structure:**

```
JazzPicker/JazzPicker/
├── App/        # Entry point, ContentView with tabs
├── Models/     # Song, Instrument, PDFNavigationContext, Setlist
├── Views/      # Browse/, PDF/, Settings/, Setlists/, Components/
└── Services/   # APIClient, CatalogStore, CachedKeysStore, SetlistStore, PDFCacheService
```

**Key patterns:**

- `@Observable` for stores (CatalogStore, CachedKeysStore, SetlistStore, PDFCacheService)
- Environment injection from JazzPickerApp
- `async/await` throughout
- PDFKit for rendering with crop bounds
- UserDefaults for setlist persistence (server sync planned)
- PDFKit with full-bleed display (no shadows/margins)
- Offline PDF caching in Documents/PDFCache/ with JSON manifest

**TestFlight:** Any iOS Device (arm64) → Archive → Distribute

---

## Backend

```bash
python3 app.py          # localhost:5001
fly deploy              # Deploy
```

**Endpoints:**

- `GET /api/v2/catalog` — All songs
- `GET /api/v2/cached-keys?transposition=C&clef=treble` — Bulk cached keys
- `POST /api/v2/generate` — Generate/fetch PDF

**Generate request:**

```json
{
  "song": "502 Blues",
  "concert_key": "ef",
  "instrument_transposition": "Bb",
  "clef": "treble"
}
```

---

## Transposition Model

| Term          | Definition                        |
| ------------- | --------------------------------- |
| Concert Key   | Key audience hears (stored in DB) |
| Written Key   | What player sees on chart         |
| Transposition | Instrument category: C, Bb, Eb    |

**Math:** `Written = Concert + instrument interval`

Bb trumpet playing concert Eb → sees F (+M2)

---

## S3 Cache

PDFs cached as: `{slug}-{concert-key}-{transposition}-{clef}.pdf`

Example: `blue-bossa-ef-Bb-treble.pdf`

---

## Docs

```
docs/
├── CLAUDE.md          # This file
├── ROADMAP.md         # Phases, current state, session history
├── SETLIST_UX.md      # UX spec for Phase 2
└── PHASE_3_4_PLAN.md  # Offline storage + shared setlists spec
```

## Key Components

| File | Purpose |
|------|---------|
| `Services/PDFCacheService.swift` | Offline PDF cache with ETag freshness |
| `Views/Components/KeyPickerSheet.swift` | 12-key grid picker for Change Key |
| `Views/Components/KeyPill.swift` | Key badge on song cards |
| `Views/Setlists/SetlistDetailView.swift` | Setlist song list + perform mode + reorder |
| `Views/PDF/PDFViewerView.swift` | PDF display with edge-tap navigation + caching |
| `Views/Settings/SettingsView.swift` | Instrument picker + cache info + About page |
| `Resources/BuildHistory.json` | Release notes for About page |
| `Scripts/increment_build.sh` | Auto-increment build on Archive |
