# Jazz Picker Roadmap

## Current State

Phase 2 in progress. Setlist foundation built, perform mode needs fix.

**What works:**
- Browse (grid on iPad, list on iPhone) → tap → PDF
- PDF: swipe L/R songs, swipe down close, menu → Change Key, Add to Setlist
- Key pills on cards (green=standard, orange=cached)
- Spin → random song
- Controls auto-hide (8s), tab bar hidden in PDF view
- Setlists: create, delete, add songs, view detail

**Known issues:**
- Setlist perform mode: swipe L/R not navigating between songs
- Spin tab placeholder briefly visible before PDF appears
- New keys don't show as pills until app refresh

**Next:** Fix setlist perform mode swipe navigation

---

## Phases

### Phase 1: Core Browsing ✓
- [x] Browse, search, PDF viewer, settings
- [x] Swipe navigation, 2-up landscape
- [x] Change Key feature with key pills

### Phase 2: Setlists
- [x] Setlist + SetlistItem models
- [x] SetlistStore (UserDefaults persistence)
- [x] Setlist views (list, detail)
- [x] Add to Setlist flow
- [ ] Perform mode (swipe navigation broken)
- [ ] Edit mode (reorder, set breaks)
- [ ] iCloud sync

### Phase 3: Offline & Polish
- [ ] PDFCache service
- [ ] Download for Offline
- [ ] Home page

### Phase 4: Mac Support
- [ ] macOS target, sidebar nav

---

## Architecture

- **Stores:** `@Observable` classes (CatalogStore, CachedKeysStore)
- **Setlists:** UserDefaults now, iCloud later
- **PDF:** SwiftUI + PDFKit with crop bounds
- **Auth:** None for v1

---

## Session History

### Dec 4, 2025 (evening)
- Setlist data layer: models, SetlistStore, UserDefaults persistence
- Setlist UI: list view, detail view, add-to-setlist sheet
- PDF viewer: Add to Setlist menu item, hide tab bar
- Known issue: setlist perform mode swipe not working

### Dec 4, 2025 (afternoon)
- Change Key: grid picker, key pills, sticky keys
- Backend: `/api/v2/cached-keys` bulk endpoint
- Fixed search keyboard, extended controls timer

### Dec 4, 2025 (morning)
- Setlist UX spec, iPad grid layout
- Fixed Baby Elephant bug, key format normalization

### Dec 4, 2025 (earlier)
- PDF swipe navigation, haptic feedback
- Swift 6 concurrency fixes
- First TestFlight build

### Dec 2-3
- Phase 1 implementation
- Decided on native SwiftUI rewrite
