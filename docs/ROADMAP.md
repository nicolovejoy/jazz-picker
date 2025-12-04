# Jazz Picker Roadmap

## Current State

Phase 1 (Core Browsing MVP) is **complete** and on TestFlight as "JazzPickerNative".

**Bundle ID:** `com.pianohouseproject.jazzpicker-native`

---

## Implementation Phases

### Phase 1: Core Browsing (MVP) - COMPLETE ✓
- [x] Project setup, folder structure
- [x] Song model + APIClient
- [x] CatalogStore with local caching
- [x] BrowseView with search
- [x] PDFViewerView (SwiftUI + PDFKit)
- [x] Instrument model + Settings (UserDefaults)
- [x] Tab navigation shell
- [x] PDF viewer: auto-hide controls (2s timer)
- [x] PDF viewer: landscape 2-up mode
- [x] App icon
- [x] PDF viewer: swipe L/R for song navigation, swipe down to close
- [ ] Browse: grid layout for iPad (cards instead of list)

### Phase 2: Setlists
- [ ] Setlist model
- [ ] iCloud sync (NSUbiquitousKeyValueStore)
- [ ] SetlistListView (list, create, delete)
- [ ] SetlistDetailView (perform mode)
- [ ] SetlistEditView (reorder, add, remove)
- [ ] Swipe between songs in PDF viewer

### Phase 3: Offline & Polish
- [ ] PDFCache service
- [ ] "Download for Offline" on setlist
- [ ] Spin button with animation

### Phase 4: Mac Support
- [ ] Add macOS target
- [ ] Sidebar navigation for Mac
- [ ] Keyboard shortcuts, menu bar

### Phase 5: Auth & Sharing (Future)
- [ ] Sign in with Apple
- [ ] Server-side setlist backup
- [ ] Shareable setlists

---

## Architecture Decisions

- **Setlists:** iCloud sync (NSUbiquitousKeyValueStore)
- **Offline:** Pre-download setlist PDFs to device
- **Catalog:** Cache locally as JSON, refresh on pull
- **Auth:** None for v1, Sign in with Apple later
- **PDF Viewer:** Pure SwiftUI + PDFKit

---

## Project Structure

```
jazz-picker/
├── app.py                    # Backend (Flask on Fly.io)
├── frontend/                 # Hybrid Capacitor app (deprecated)
├── JazzPicker/               # Native SwiftUI app
│   ├── JazzPicker.xcodeproj
│   └── JazzPicker/
│       ├── App/
│       ├── Models/
│       ├── Views/
│       └── Services/
└── docs/
```

---

## Stack

| Component | Location |
|-----------|----------|
| Web | jazzpicker.pianohouseproject.org (Vercel) |
| iOS (hybrid) | TestFlight (deprecated) |
| iOS (native) | TestFlight as "JazzPickerNative" |
| Backend | jazz-picker.fly.dev (Fly.io) |
| PDFs | AWS S3 |

---

## Session History

### Dec 4, 2025 (late evening)
- Fixed key format bug: catalog uses `eb` but API expects `ef` - added client-side conversion in APIClient.swift
- Spin + swipe navigation now fully working
- Major CLAUDE.md cleanup: 727 → 180 lines (removed deprecated Capacitor details, consolidated)
- Identified next tasks: key normalization at source (build_catalog.py), "Baby Elephant" bug

### Dec 4, 2025 (evening)
- Implemented PDF swipe navigation: L/R for songs at page boundaries, down to close
- Created `PDFNavigationContext` enum with browse/setlist/spin/single modes
- Added PDFKit Coordinator for page change detection
- Haptic feedback at list boundaries
- Fixed Swift 6 concurrency warnings (added `Sendable` to models, refactored `APIClient`)
- Fixed: error state now shows toolbar + "Go Back" button (was getting stuck)
- Added loading overlay for song transitions (dark overlay + spinner over previous PDF)
- Added debug logging throughout PDF loading pipeline
- Improved APIClient error reporting (status code + response body)

### Dec 4, 2025 (later)
- Cleaned up docs: deleted DEBUG_PLAN.md, merged HANDOFF.md into ROADMAP.md
- Designed PDF navigation gestures (swipe L/R for songs, swipe down to close)
- Documented transposition data model (`instrument_transposition` param)
- Added navigation context enum for browse/setlist/spin modes

### Dec 4, 2025
- PDF viewer: auto-hide controls (2s), landscape 2-up mode
- App icon created and added
- First TestFlight build submitted as "JazzPickerNative"
- Phase 1 complete

### Dec 4 (earlier)
- Created native SwiftUI project structure
- Implemented Phase 1: Browse, Search, PDF viewer, Settings
- Decided on native Swift rewrite
- Created SWIFT_ARCHITECTURE.md

### Dec 2-3
- Spin roulette wheel feature (hybrid)
- PDF transition overlay
- Catalog navigation (swipe through songs)
- MIDI note range extraction (739 songs)
- TestFlight PDF rendering fix attempts (led to rewrite decision)

---

## Legacy Hybrid App

The Capacitor/React hybrid app (`frontend/ios/`) is deprecated but still functional on TestFlight. Features implemented there (for reference when porting):
- Full bleed PDF display - 2-up landscape, 97% scale
- Setlist Edit mode - drag-drop, reorder, key +/−
- Spin - roulette wheel action button
- PDF transitions - loading overlay
- Catalog navigation - alphabetical swipe

---

_Last updated: 2025-12-04_
