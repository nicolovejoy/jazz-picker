# Session Handoff - Dec 3, 2025

## RESOLVED: TestFlight PDFs Now Working

The iOS PDF viewing issue has been fixed. Root cause was plugin registration timing.

### What Was Fixed
1. **Plugin registration timing** — Was using delayed `asyncAfter(0.5)`, now registers in `applicationDidBecomeActive`
2. **View hierarchy check** — Added guard to retry if view not in window hierarchy
3. **Double-call handling** — Detects if already presenting and handles gracefully

### Current State
- TestFlight builds now work
- PDFs render correctly
- Controls (X button, setlist badge) auto-hide after 1.5s

## In Progress: Full Bleed PDF Display

Working on removing margins/gutter for edge-to-edge PDF display. Current issues:
- Margins visible around PDF content
- Gutter visible between pages in landscape (switched to single-page mode as workaround)
- Status bar/home indicator still showing in TestFlight

## Outstanding Todo Items

1. **Full bleed display** — Remove remaining margins, hide status bar properly
2. **Add to Setlist button** — Add to PDF viewer controls
3. **Setlist badge position** — Shows catalog position (12/735) instead of setlist position (6/7)
4. **Setlist swipe navigation** — Erratic, sometimes flashes back to setlist
5. **Spin animation** — Make more engaging (grows/expands)

---

## Completed This Session: Note Range Extraction

Successfully implemented MIDI-based note range extraction for the catalog.

### What Was Built

1. **`build_catalog.py`** - New script that:
   - Scans `*Standard.ly` wrapper files
   - Runs LilyPond to generate MIDI (skips PDF with `-dno-print-pages`)
   - Parses MIDI to extract melody note range (program 29 = "overdriven guitar")
   - Filters outlier notes >12 semitones below median (catches `\voiceTwo` bass fills)
   - Stores `low_note_midi`, `high_note_midi` in catalog.db
   - Generates `outlier_report.txt` listing filtered notes
   - Fails build completely on any MIDI generation error

2. **`db.py` updates**:
   - Added `get_song_note_range(title)` function
   - Updated `get_song_by_title()` to include note range columns

3. **Configuration** (top of `build_catalog.py`):
   ```python
   OUTLIER_THRESHOLD_SEMITONES = 12  # 1 octave below median
   ```

### Build Results
- **739 songs** processed successfully
- **43 songs** had outlier notes filtered (documented in `outlier_report.txt`)
- Build takes ~10-15 minutes for all songs

### Next Steps (After PDF Fix)

1. **Integrate note ranges into `app.py`**
   - Use `low_note_midi` to calculate octave marker for bass clef
   - Set `whatKey` with `,` suffix when needed to keep melody in readable range

2. **Upload new catalog.db to S3**
   ```bash
   aws s3 cp catalog.db s3://jazz-picker-pdfs/catalog.db
   fly apps restart jazz-picker
   ```

3. **Clear S3 cache** (bass clef PDFs will need regeneration)
   ```bash
   aws s3 rm s3://jazz-picker-pdfs/generated/ --recursive
   ```

---

## Quick Reference

### MIDI Note Numbers
```
C2 = 36, E2 = 40 (target low for bass clef)
C3 = 48, C4 = 60 (middle C), C5 = 72
```

### LilyPond Octave Notation
```
c, = C2    c = C3    c' = C4 (middle C)    c'' = C5
```

### Key Files

| File | Purpose |
|------|---------|
| `build_catalog.py` | Catalog builder with MIDI parsing |
| `extract_note_ranges.py` | Standalone PoC for testing individual songs |
| `outlier_report.txt` | Lists songs with filtered bass fill notes |
| `app.py:generate_wrapper_content()` | Where octave calculation will be added |

---

## Current Stack

| Component | Location |
|-----------|----------|
| Web | jazzpicker.pianohouseproject.org (Vercel) |
| iOS | TestFlight Build 9 (broken) |
| Backend | jazz-picker.fly.dev (Fly.io) |
| PDFs | AWS S3 |
| LilyPond source | lilypond-data/ submodule |

---

## Previous Work (Dec 2-3)

- Spin roulette wheel feature
- PDF transition overlay
- Catalog navigation (swipe through songs)
- Offline caching attempt (reverted - caused PDF rendering failure)
- MIDI note range extraction (completed)
