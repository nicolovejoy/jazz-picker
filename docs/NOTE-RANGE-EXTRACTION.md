# Note Range Extraction: Using Eric's Ambitus Output

## Background

The Jazz Picker catalog includes melody note ranges for each song (low/high MIDI note numbers). This data enables future features like auto-transposition based on instrument range.

Previously, `build_catalog.py` generated MIDI files and used the `mido` Python library to parse them. This is why the GitHub workflow has been failing - `mido` wasn't installed.

## Eric's Ambitus Enhancement

Eric's recent commit (`56c0d5a`) added `ambitus-engraver.ily`, which outputs the melody range directly to the LilyPond log during processing:

```
low note #<Pitch b >
high note #<Pitch d'' >
```

This is cleaner than our MIDI approach because:
- No extra dependencies (no `mido`)
- The source data comes directly from LilyPond's analysis
- Single source of truth (Eric's repo)

## Proposed Changes

### 1. Switch to log parsing

Update `build_catalog.py` to:
- Capture LilyPond's stdout when processing each wrapper
- Parse "low note" / "high note" lines
- Convert LilyPond pitch notation to MIDI numbers

Example: `d''` → MIDI 74 (D5)

### 2. Simplify the workflow

The GitHub workflow in Eric's repo won't need to install `mido` anymore. It just runs `build_catalog.py` which parses the log output.

### 3. Clean up

- Remove `mido` from `requirements.txt`
- Delete `extract_note_ranges.py` (superseded)

## Pitch Conversion Reference

LilyPond pitch format: `[note][accidental][octave_marks]`

Notes (semitones from C):
- c=0, d=2, e=4, f=5, g=7, a=9, b=11

Accidentals:
- `is` = sharp (+1)
- `es` = flat (-1)
- `isis` = double sharp (+2)
- `eses` = double flat (-2)

Octave marks:
- Each `'` = +12 (octave up)
- Each `,` = -12 (octave down)
- Base (no marks): middle octave, C = MIDI 48

Examples:
- `c'` = MIDI 60 (middle C)
- `b` = MIDI 59 (B below middle C)
- `d''` = MIDI 74 (D5)
- `fis'` = MIDI 66 (F#4)

## Status

Waiting on Eric's confirmation before implementing. No action needed from Eric - just want to make sure this approach works for both of us.
