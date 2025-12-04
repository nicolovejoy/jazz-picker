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
- [x] Browse: grid layout for iPad (cards instead of list)

### Phase 2: Setlists
UX spec: `docs/SETLIST_UX.md`

- [x] PDF viewer: Change Key (circle-of-fifths wheel)
- [x] Browse cards: Key pills (green=standard, orange=cached)
- [x] Backend: `/api/v2/cached-keys` bulk endpoint
- [ ] Setlist + SetlistItem models (with set break support)
- [ ] SetlistStore (CRUD, soft delete, UserDefaults → iCloud later)
- [ ] SetlistListView (cards, sorted by recency, swipe-delete with confirm)
- [ ] SetlistDetailView (song list, tap to perform)
- [ ] SetlistEditView (reorder, multi-select, set breaks)
- [ ] PDF viewer: Add to Setlist flow
- [ ] Setlist perform mode (swipe between songs, position indicator)

### Phase 3: Offline & Polish
- [ ] PDFCache service
- [ ] "Download for Offline" on setlist
- [ ] Spin button with animation
- [ ] Home page (app info, recent setlist 1-click, browse ~50% of screen, refresh button for cached keys)

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

### Dec 4, 2025 (afternoon)
- Implemented Change Key feature
- Added `/api/v2/cached-keys` bulk endpoint to backend (deployed)
- Created `CachedKeysStore` service for iOS with local caching
- Updated SongCard with key pills (green=standard, orange=cached)
- Added sticky key support (persists for session)
- Key picker: started with circle-of-fifths wheel, simplified to 2-row grid
- PDF viewer: menu → Change Key → grid picker → loads new PDF
- Context-aware sharp/flat spelling based on song's standard key
- Fixed search keyboard not appearing (gesture conflict with cards)
- Extended controls auto-hide timer to 8 seconds
- Known issue: new keys don't appear as pills until cache refresh

### Dec 4, 2025 (later morning)
- Designed full Setlist UX through Q&A process
- Created `docs/SETLIST_UX.md` spec covering: key changes, add-to-setlist, perform mode, edit mode, set breaks
- Widened iPad grid cards (320px min)

### Dec 4, 2025 (morning)
- Fixed "Baby Elephant Walk" bug: added `bassKey` to `generate_wrapper_content()`
- Fixed key format: rebuilt catalog.db with `ef`/`bf`/`af`/`df` format, removed iOS workaround
- Added iPad grid layout for Browse view (cards via `LazyVGrid`, iPhone keeps list)
- Deployed backend to Fly.io

### Dec 4, 2025 (late night)
- Committed full SwiftUI folder structure (`b6a13d5`)
- Diagnosed "Baby Elephant Walk" bug: missing `bassKey` in `generate_wrapper_content()`
- Documented fix plan in HANDOFF.md with exact code snippet
- Ready for backend fix + deploy

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
