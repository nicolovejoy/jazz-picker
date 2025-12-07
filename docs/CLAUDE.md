# CLAUDE.md

## Project Overview

Jazz Picker is an iPad music stand. ~730 songs from Eric's lilypond-lead-sheets repo.

| Component | Location | Notes |
|-----------|----------|-------|
| iOS App | `JazzPicker/` (SwiftUI) | Main focus |
| Backend | `app.py` (Flask on Fly.io) | PDF gen + setlists API |
| Web | `frontend/` (React) | Simplified, no auth |

---

## iOS App

```bash
open JazzPicker/JazzPicker.xcodeproj
```

**Structure:**
```
JazzPicker/JazzPicker/
├── App/        # Entry point, tabs
├── Models/     # Song, Instrument, Setlist, etc.
├── Views/      # Browse/, PDF/, Settings/, Setlists/
└── Services/   # APIClient, SetlistStore, PDFCacheService, NetworkMonitor, DeviceID
```

**Key patterns:**
- `@Observable` stores injected via environment
- Setlists sync to server API (optimistic UI with rollback)
- Offline PDF caching in Documents/PDFCache/
- NetworkMonitor disables edit controls when offline

**TestFlight:** Any iOS Device (arm64) → Archive → Distribute

---

## Backend

```bash
python3 app.py          # localhost:5001
fly deploy              # Deploy to Fly.io
```

**API endpoints:**
- `GET /api/v2/catalog` — All songs
- `POST /api/v2/generate` — Generate PDF (supports `octave_offset`: -2 to +2)
- `GET/POST/PUT/DELETE /api/v2/setlists` — Setlist CRUD

**Note:** 2 Fly machines with separate SQLite files. Requests may hit different machines (data inconsistency possible). Fine for dev.

---

## Transposition Model

| Term | Definition |
|------|------------|
| Concert Key | Key audience hears (stored in DB, shared in setlists) |
| Written Key | What player sees on chart |
| Transposition | Instrument: C, Bb, Eb |
| Octave Offset | Per-device adjustment when transposition lands in wrong octave |

**Setlist sharing:** Concert key is shared. Each device applies its own transposition + clef + octave.

---

## Testing

Test against production (not local dev):
- **Web:** https://jazzpicker.pianohouseproject.org
- **API:** https://jazz-picker.fly.dev
- **iOS:** TestFlight build pointing to production API

Local dev only needed when changing backend code before `fly deploy`.

---

## Key Files

| File | Purpose |
|------|---------|
| `Services/SetlistStore.swift` | API sync, optimistic UI |
| `Services/NetworkMonitor.swift` | Connectivity detection |
| `Services/DeviceID.swift` | Keychain-persisted UUID |
| `Services/PDFCacheService.swift` | Offline PDF cache (key: song+key+transposition+clef+octave) |
| `Views/PDF/PDFViewerView.swift` | PDF display, edge-tap nav |
| `Resources/BuildHistory.json` | Release notes for About page |
