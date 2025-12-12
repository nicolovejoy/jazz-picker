# Note Range Extraction

**Status:** Waiting on Eric's confirmation before implementing.

## Problem
GitHub workflow fails because `build_catalog.py` uses `mido` for MIDI parsing, but `mido` isn't installed.

## Solution
Eric's `ambitus-engraver.ily` outputs note ranges to LilyPond's log:
```
low note #<Pitch b >
high note #<Pitch d'' >
```

Switch to parsing this instead of MIDI. Benefits:
- No dependencies
- Single source of truth (Eric's repo)

## Changes Required
1. Update `build_catalog.py` to parse log output
2. Remove `mido` from `requirements.txt`
3. Delete `extract_note_ranges.py`
4. Update workflow (no pip install needed)

## Pitch Conversion

Format: `[note][accidental][octave_marks]`

- Notes: c=0, d=2, e=4, f=5, g=7, a=9, b=11
- Accidentals: `is`=+1, `es`=-1
- Octave: `'`=+12, `,`=-12
- Base: C (no marks) = MIDI 48

Examples: `c'`=60, `b`=59, `d''`=74, `fis'`=66
