# Jazz Picker Roadmap

## Current State

Phase 3 complete. Offline PDF caching ready.

**What works:**

- Browse (grid on iPad, list on iPhone) → tap → PDF
- PDF: edge tap for prev/next song, swipe for pages, swipe down close
- Key pills on cards (green=standard, orange=cached)
- Change Key with 12-key picker
- Spin → random song
- Setlists: create, delete, add songs, reorder, perform mode
- Settings: instrument picker, About page with build history
- Offline PDF caching with ETag-based freshness
- Auto-download setlist songs when viewing a setlist
- Subtle cache indicator on song cards/rows
- Cache management in Settings (count, size, clear)

**Known issues:**

- Spin tab placeholder briefly visible before PDF appears
- New keys don't show as pills until app refresh

---

## Phases

### Phase 1: Core Browsing ✓

- [x] Browse, search, PDF viewer, settings
- [x] Swipe navigation, 2-up landscape
- [x] Change Key feature with key pills

### Phase 2: Setlists ✓

- [x] Setlist + SetlistItem models
- [x] SetlistStore (UserDefaults persistence)
- [x] Setlist views (list, detail)
- [x] Add to Setlist flow
- [x] Perform mode (edge tap navigation)
- [x] Edit mode (reorder songs)
- [ ] iCloud sync (deferred)

### Phase 3: Offline PDF Storage ✓

- [x] PDFCacheService (auto-cache viewed PDFs, ETag-based freshness)
- [x] Cache indicator on song cards (subtle download icon)
- [x] Auto-download setlist songs on view
- [x] Cache info in Settings (count, size, clear)

### Phase 4: Shared Setlists

- [ ] Backend: setlists table + REST endpoints
- [ ] Device ID identity (Keychain)
- [ ] SetlistStore → API sync
- [ ] Pull-to-refresh, loading states
- [ ] Migrate UserDefaults setlists to server

### Phase 5: Future

- [ ] Apple Sign-In
- [ ] Private/public setlist toggle
- [ ] macOS target, sidebar nav
- [ ] Home page

---

## Architecture

- **Stores:** `@Observable` classes (CatalogStore, CachedKeysStore, SetlistStore)
- **Setlists:** UserDefaults now → server API (Phase 4)
- **PDF:** SwiftUI + PDFKit with crop bounds, full-bleed display
- **Auth:** Device ID now → Apple Sign-In (Phase 5)

---

## Session History

### Dec 4, 2025 (session 3)

- Phase 3 complete: Offline PDF caching
- PDFCacheService with JSON manifest, Documents/ storage
- ETag-based freshness (conditional GET with If-None-Match)
- Auto-download setlist songs when viewing setlist
- Subtle cache indicator on Browse cards, SongRow, Setlist rows
- Cache management in Settings (count, size, clear button)

### Dec 4, 2025 (session 2)

- PDF viewer: full-bleed display (removed shadows/margins)
- Planned Phase 3 (offline PDF caching) and Phase 4 (shared setlists)
- Created PHASE_3_4_PLAN.md spec

### Dec 4, 2025 (session 1)

- Phase 2 complete: setlists with perform mode, reorder, edge-tap navigation
- Change Key feature with key pills
- About page with build history tracking
- Build 2 pushed to TestFlight

### Dec 2-3, 2025

- Phase 1: SwiftUI rewrite, browse/search/PDF viewer
- First TestFlight build
