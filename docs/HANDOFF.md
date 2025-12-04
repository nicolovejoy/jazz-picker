# Session Handoff - Dec 3, 2025

## BLOCKER: TestFlight Build Needed

The PDF viewer improvements work in local Xcode builds but TestFlight still has the old version. Need to:

1. Open Xcode: `open frontend/ios/App/App.xcworkspace`
2. Select "Any iOS Device (arm64)"
3. Product → Archive
4. Distribute App → App Store Connect → Upload
5. Wait ~15 min for processing

## Just Completed: iOS PDF Viewer Improvements

### Full Bleed Display (DONE - needs TestFlight build)
- Removed black margins and gutter from PDFView
- Landscape mode now shows 2-up (side-by-side pages)
- 97% scale for breathing room around edges
- Auto-hiding controls working (1.5s timer)
- Added debouncing (300ms) to prevent rapid open/close race conditions

### Infinite Scroll Fix (DONE)
- Fixed duplicate songs appearing when scrolling
- Root cause: `keepPreviousData` caused stale data to be processed
- Added `!isFetching` check and title-based deduplication

### Key Format Fix (DONE)
- Catalog stored keys as `am`, `bb` but backend expected `a`, `bf`
- Added `normalizeKey()` in frontend as temporary fix
- Fixed `build_catalog.py` to output correct format (for future rebuild)

### Catalog Uploaded
- New catalog.db with note ranges uploaded to S3
- Fly.io restarted to pick up new catalog

---

## Outstanding Todo Items

1. **Add to Setlist button** — Add to PDF viewer top controls
2. **Fix setlist badge** — Shows catalog position (12/735) instead of setlist position (6/7)
3. **Fix setlist swipe navigation** — Erratic, sometimes flashes back
4. **Improve Spin animation** — More engaging visual feedback
5. **bassKey octave calculation** — Use note ranges to set octave for bass clef

---

## Quick Reference

### Key Files Changed This Session

| File | Changes |
|------|---------|
| `NativePDFViewController.swift` | 2-up landscape, 97% scale, chrome removal, timer fix |
| `NativePDFPlugin.swift` | 300ms debounce for rapid opens |
| `App.tsx` | Infinite scroll fix (isFetching check, dedup) |
| `api.ts` | `normalizeKey()` for catalog key format |
| `build_catalog.py` | Fixed key format (bb→bf, strip 'm') |

### TestFlight
Ready for new build - all iOS fixes committed and pushed.

---

## Current Stack

| Component | Location |
|-----------|----------|
| Web | jazzpicker.pianohouseproject.org (Vercel) |
| iOS | TestFlight (pending new build) |
| Backend | jazz-picker.fly.dev (Fly.io) |
| PDFs | AWS S3 |
| LilyPond source | lilypond-data/ submodule |

---

## Previous Sessions

### Dec 2-3
- Spin roulette wheel feature
- PDF transition overlay
- Catalog navigation (swipe through songs)
- MIDI note range extraction (739 songs)
- TestFlight PDF rendering fix (plugin registration timing)
