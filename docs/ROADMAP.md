# Jazz Picker Roadmap

## Current State

Phase 2 in progress. Setlist perform mode complete, edit mode next.

**What works:**
- Browse (grid on iPad, list on iPhone) → tap → PDF
- PDF: edge tap for prev/next song, swipe for pages, swipe down close
- Chevron indicators appear with controls (2s timeout)
- Key pills on cards (green=standard, orange=cached)
- Spin → random song
- Setlists: create, delete, add songs, view detail, perform mode

**Known issues:**
- Spin tab placeholder briefly visible before PDF appears
- New keys don't show as pills until app refresh

**Next:** Edit mode - reorder songs in setlist

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
- [x] Perform mode (edge tap navigation)
- [ ] Edit mode (reorder songs) ← **next**
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

### Dec 4, 2025 (late night)
- Renamed CircleOfFifthsWheel.swift → KeyPickerSheet.swift (cleanup)
- Removed unused code, fixed stray character build error
- Attempted bottom tab bar restoration (.tabViewStyle(.tabBarOnly)) - didn't work on iPad, reverted

### Dec 4, 2025 (night)
- Fixed PDF navigation: replaced swipe gestures with edge tap zones
- Added chevron indicators (appear with controls, 2s timeout)
- Haptic feedback on navigation and boundaries
- Removed set breaks from scope

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
