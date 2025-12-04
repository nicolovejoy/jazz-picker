# Handoff - Dec 4, 2025 Late Night

## Current State

Native SwiftUI app fully working. Spin + swipe navigation functional after key format fix.

**Uncommitted:** Large SwiftUI restructure (App/, Models/, Views/, Services/ folders). Commit before starting new work.

---

## Next Session: Two Backend Fixes

### 1. Baby Elephant Bug (Priority)

**Symptom:** First 4 bars of "Baby Elephant Walk" show chord symbols but no melody (for any instrument).

**Root cause:** `app.py:generate_wrapper_content()` is missing `bassKey` variable.

**How it breaks:**
- `bass-intro.ily:19` does `\transpose \refrainKey \bassKey { \bassIntro }`
- When `bassKey` undefined, LilyPond silently skips the intro section
- Eric's static wrappers work because they define `bassKey`

**The fix** in `app.py:generate_wrapper_content()` (~line 356):

```python
def generate_wrapper_content(core_file, target_key, clef, instrument=""):
    # bassKey is always the key without octave modifier
    bass_key = target_key.rstrip(',')

    # For bass clef, whatKey needs octave-down comma
    what_key = f"{target_key}," if clef == "bass" else target_key

    return f'''%% -*- Mode: LilyPond -*-

\\version "2.24.0"

\\include "english.ly"

instrument = "{instrument}"
whatKey = {what_key}
bassKey = {bass_key}
whatClef = "{clef}"

\\include "../Core/{core_file}"
'''
```

**Test:** Generate "Baby Elephant Walk" for Piano. First 4 bars should have melody notes, not just "F" chord symbols.

**Deploy:** `fly deploy`

---

### 2. Key Format Normalization (Lower Priority)

**Problem:** Catalog stores flats as `eb` (b=flat), but backend expects `ef` (f=flat).

**Current workaround:** `APIClient.swift:63-66` converts `eb` → `ef` client-side.

**Proper fix:** Update `build_catalog.py` to output `ef` format at source, then remove iOS workaround.

**Files:**
- `build_catalog.py` — change key output format
- `JazzPicker/JazzPicker/Services/APIClient.swift` — remove workaround after deploy

---

## What Works (All ✓)

- Browse → tap song → PDF loads
- Swipe L/R between songs (browse + spin modes)
- Swipe down to dismiss
- Spin → random song → swipe to more random songs
- Loading overlay during transitions
- Error state with back button

## Quick Reference

```bash
# iOS development
open JazzPicker/JazzPicker.xcodeproj

# Backend
python3 app.py          # localhost:5001
fly deploy              # Deploy to Fly.io
fly logs                # View logs

# Test Baby Elephant fix locally before deploy
curl -X POST http://localhost:5001/api/v2/generate \
  -H "Content-Type: application/json" \
  -d '{"song":"Baby Elephant Walk","concert_key":"f","transposition":"C","clef":"treble","instrument_label":"Piano"}'
```
