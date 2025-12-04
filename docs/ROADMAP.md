# Jazz Picker Roadmap

## Current State

Phase 1 complete. Change Key feature done. Ready for TestFlight.

**What works:**
- Browse (grid on iPad, list on iPhone) → tap → PDF
- PDF: swipe L/R songs, swipe down close, menu → Change Key
- Key pills on cards (green=standard, orange=cached)
- Spin → random song
- Controls auto-hide (8s)

**Known issues:**
- New keys don't show as pills until app refresh
- "Baby Elephant Walk" fails to generate (bassKey issue)

**Next:** Setlist data layer (see `SETLIST_UX.md`)

---

## Phases

### Phase 1: Core Browsing ✓
- [x] Browse, search, PDF viewer, settings
- [x] Swipe navigation, 2-up landscape
- [x] Change Key feature with key pills

### Phase 2: Setlists
- [ ] Setlist + SetlistItem models
- [ ] SetlistStore (UserDefaults → iCloud)
- [ ] Setlist views (list, detail, edit)
- [ ] Add to Setlist flow
- [ ] Perform mode

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
