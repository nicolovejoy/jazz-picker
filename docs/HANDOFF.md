# Handoff - Dec 4, 2025

## Current State

Change Key feature implemented and working. Ready for TestFlight.

---

## Completed This Session

1. **Change Key Feature**
   - Backend: `/api/v2/cached-keys` bulk endpoint (deployed)
   - iOS: `CachedKeysStore` service with local caching
   - iOS: Key picker grid (simple 2-row layout, tap to select)
   - iOS: Key pills on SongCard (green=standard, orange=cached)
   - PDF viewer: Menu → Change Key → grid picker → tap key → new PDF loads

2. **Key Pills on Browse Cards**
   - Standard key (green) always leftmost
   - Sticky key (session) promoted to 2nd position
   - Context-aware sharp/flat spelling based on song's standard key
   - Tap pill → opens in that key, tap card title → standard key

3. **Bug Fixes**
   - Fixed search keyboard not appearing (was gesture conflict)
   - Fixed controls disappearing too fast (now 8 seconds)
   - Simplified key picker from wheel to grid (clearer UX)

---

## Known Issues / Next Session

1. **New keys not cached locally** — When you generate a PDF in a new key, the key pill doesn't appear on the Browse card until next app launch (needs to refresh from server or add to local cache after generation)

2. **Home page** — Planned for Phase 3: app info, recent setlist 1-click, browse ~50%, refresh button

---

## What Works

- Browse (grid on iPad, list on iPhone) → tap → PDF
- PDF: swipe L/R between songs, swipe down to close
- PDF: Menu → Change Key → 12-key grid picker
- Key pills on cards show cached keys from S3
- Sticky keys persist for session
- Spin → random song → swipe for more
- Controls auto-hide after 8 seconds

---

## Files Changed This Session

**Backend:**
- `app.py` — Added `/api/v2/cached-keys` bulk endpoint

**iOS - New:**
- `Services/CachedKeysStore.swift`
- `Views/Components/CircleOfFifthsWheel.swift` (now contains KeyPickerGrid)

**iOS - Modified:**
- `App/JazzPickerApp.swift` — Added CachedKeysStore environment
- `App/ContentView.swift` — Added CachedKeysStore environment
- `Services/APIClient.swift` — Added fetchAllCachedKeys
- `Models/Song.swift` — Added BulkCachedKeysResponse
- `Views/Browse/BrowseView.swift` — Load cached keys, pass key to PDF
- `Views/Browse/SongCard.swift` — Key pills with tap handlers
- `Views/PDF/PDFViewerView.swift` — Change Key menu + sheet

---

## Quick Reference

```bash
open JazzPicker/JazzPicker.xcodeproj   # iOS dev
python3 app.py                          # Backend local
fly deploy                              # Deploy backend
```
