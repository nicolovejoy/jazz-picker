# Session Handoff - Dec 3, 2025

## Current Focus: Extracting Note Ranges from Core Files

### The Goal

Jazz Picker needs to set `whatKey` with correct octave markers (`,` or `'`) when generating bass clef PDFs. To do this, we need to know each song's **note range** (low note, high note).

### python-ly Investigation Results (Dec 3 - Session 2)

**Conclusion:** python-ly works partially but has bugs with complex files.

**What Works:**
- `pip install python-ly` installs cleanly (v0.9.9)
- `ly.document.Document()` parses LilyPond files into a tree
- `ly.music.document()` creates a navigable music tree with Note, Chord, Relative items
- Can find `refrainMelody` assignment and extract notes
- `Pitch.makeAbsolute()` calculates absolute pitch from relative notation

**What Doesn't Work:**
- The relative-to-absolute conversion drifts on files with repeated sections (A1, A2, A3)
- `ly.pitch.rel2abs.rel2abs()` has same issue - produces `c,,,,` (MIDI 0) for some songs
- The drift happens because section repeats don't reset the relative pitch context

**Workaround Tested:**
- Filter MIDI values 36-96 (C2 to C7) to exclude obvious errors
- Works for most songs but some still show suspiciously high values

**Example Results (with filtering):**
| Song | Low Note | High Note | MIDI Range |
|------|----------|-----------|------------|
| Song for My Father | g | g' | 55-67 ✓ |
| Mean to Me | c, | a' | 36-69 ✓ |
| All Blues | b' | d''' | 71-86 (suspiciously high?) |

### Next Session: Decision Needed

**Option A: Accept python-ly with filtering**
- Add to `build_catalog.py` with MIDI 36-84 filter
- May produce some wrong values, but most will be usable

**Option B: Ask Eric to provide note ranges**
- He already knows the ranges (uses them in makesheet.py)
- Could add to core files as a comment or variable
- More reliable but requires Eric's time

**Option C: Try different approach**
- Regex-based extraction of note tokens
- Manual relative-to-absolute logic with section-aware reset
- More complex but potentially more accurate

**Key file with working extraction code:** See conversation history for the Python script using `extract_note_range_filtered()`

---

## Background: Why We Need Note Ranges

### The bassKey Problem

Eric's LilyPond system uses two variables for transposition:
- `whatKey` - target key for melody (may include octave marker like `f,`)
- `bassKey` - target key for bass line (pitch class only, no octave marker)

### How Eric's makesheet.py Calculates Octave

```python
# Lines 390-414: Calculate octave offset for bass clef
# Goal: lowest note no lower than E below bass staff (offset -8)
low_e_offset = -8
octave_offset = -5
bass_low_note = low_note_offset - (5 * 12)
while bass_low_note < low_e_offset:
    bass_low_note += 12
    octave_offset += 1
```

This requires knowing the song's `low_note_offset` - which comes from user input when Eric runs makesheet.py.

### What Jazz Picker Needs

For each song in the catalog, we need:
- `low_note` (e.g., `c` or `g,`)
- `high_note` (e.g., `a''`)

Then at PDF generation time:
```python
if clef == 'treble':
    whatKey = target_key
    bassKey = target_key
else:  # bass clef
    # Calculate octave offset using low_note + target_key
    octave_marker = calculate_bass_octave(low_note, target_key)
    whatKey = target_key + octave_marker  # e.g., "f,"
    bassKey = target_key                   # e.g., "f"
```

---

## Confirmed with Eric (Dec 3)

1. **bassKey rule:**
   - Treble clef: `bassKey = whatKey` (same value)
   - Bass clef: `bassKey` = pitch class only, `whatKey` = pitch + octave marker

2. **Song for My Father example:**
   | File | whatKey | bassKey | whatClef |
   |------|---------|---------|----------|
   | Fm Standard (treble) | `f` | `f` | treble |
   | Fm Bass for Standard | `f,` | `f` | bass |

3. **bassKey is harmless to set always** - even if song has no `refrainBass`

4. **Without bassKey:** LilyPond errors or warns

5. **The blocker:** Jazz Picker can't calculate the octave marker without note range data

---

## Data Model Changes Needed

### Option A: Add to Catalog (Preferred)

Modify `build_catalog.py` to extract note ranges using python-ly:

```python
# New fields in catalog.db
songs table:
  - title TEXT
  - default_key TEXT
  - low_note TEXT      # NEW: e.g., "c" or "g,"
  - high_note TEXT     # NEW: e.g., "a''"
```

### Option B: Separate JSON File

If python-ly parsing is complex, could store ranges in a separate file that Eric maintains.

---

## Quick Reference

### LilyPond Octave Notation (from makesheet.py)

```
c, = C2 (two ledger lines below bass staff)
c  = C3 (bass staff, second space from bottom)
c' = C4 (middle C)
c'' = C5 (treble staff)
c''' = C6 (two ledger lines above treble staff)
```

### Key Files

- `lilypond-data/Wrappers/makesheet.py` - Eric's octave calculation logic
- `lilypond-data/Include/refrain.ily:62-71` - Where bassKey is used
- `lilypond-data/Core/Song for My Father - Ly Core - Fm.ly` - Example with refrainBass
- `build_catalog.py` - Where we'd add note range extraction

---

## Previous Sessions

### Dec 3 - Session 2 (This Session)
- Investigated python-ly for note range extraction
- Found: works partially but drifts on complex files
- Tested filtering approach (MIDI 36-96)
- Decision needed: accept imperfect extraction vs ask Eric

### Dec 3 - Session 1
- Discussed bassKey implementation with Eric
- Identified blocker: need note ranges for octave calculation
- Decision: investigate python-ly for automatic extraction

### Dec 2
- **Spin** - Roulette wheel icon in nav bar, one-tap action
- **PDF transition overlay** - Loading spinner when swiping between songs
- **PDF viewer race condition fix** - Added key prop to Document component

---

## Current Stack

| Component | Location |
|-----------|----------|
| Web | jazzpicker.pianohouseproject.org (Vercel) |
| iOS | TestFlight (Jazz Picker) |
| Backend | jazz-picker.fly.dev (Fly.io) |
| Auth/DB | Supabase |
| PDFs | AWS S3 |
| LilyPond source | lilypond-data/ submodule (Eric's repo) |

## Quick Commands

```bash
# Update lilypond-data submodule
cd lilypond-data && git pull

# TestFlight deploy
cd frontend && npm run build && npx cap sync ios
open ios/App/App.xcworkspace
# Xcode: "Any iOS Device (arm64)" → Product → Archive → Distribute

# Deploy backend
fly deploy
```

## After bassKey is Implemented

User needs to clear S3 cache:
```bash
aws s3 rm s3://jazz-picker-pdfs/generated/ --recursive
```

## Next Up (after bassKey)

1. Setlist Edit mode (drag-drop, reorder, key +/-)
2. Offline PDF caching (commit f1fe8b2 - broken in TestFlight)
3. Pre-cache setlist PDFs on app load
4. Home page with one-click setlist access
