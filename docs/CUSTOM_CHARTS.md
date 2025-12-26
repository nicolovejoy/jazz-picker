# Custom Charts

User-submitted charts stored separately from Eric's lilypond-lead-sheets.

## Directory Structure

```
custom-charts/
├── Core/           # LilyPond source (melody, chords)
├── Wrappers/       # Key/clef selectors that include Core files
└── Generated/      # Runtime-generated wrappers (gitignored)
```

## File Naming

Same convention as Eric's charts:
- Core: `{Title} - Ly Core - {Key}.ly`
- Wrapper: `{Title} - Ly - {Key} Standard.ly`

## Adding a Custom Chart

1. Create Core file in `custom-charts/Core/`:
```lilypond
\include "../../lilypond-data/Include/lead-sheets.ily"

\header {
  title = "Song Title"
  composer = "Composer Name"
}

refrainKey = c
refrainMelody = \relative f' { ... }
% refrainChords = \chordmode { ... }  % optional

\include "../../lilypond-data/Include/paper.ily"
\include "../../lilypond-data/Include/refrain.ily"
```

2. Create Wrapper in `custom-charts/Wrappers/`:
```lilypond
\version "2.24.0"
\include "english.ly"

instrument = "Standard Key"
whatKey = c
whatClef = "treble"

\include "../Core/Song Title - Ly Core - C.ly"
```

3. Rebuild catalog:
```bash
python build_catalog.py --custom-dir custom-charts --skip-ranges
aws s3 cp catalog.db s3://jazz-picker-pdfs/catalog.db
fly deploy
```

## S3 Buckets

- Standard charts: `s3://jazz-picker-pdfs/generated/`
- Custom charts: `s3://jazz-picker-custom-pdfs/generated/`

Custom PDFs are preserved when Eric's charts are rebuilt.

## Conversion Tools

- `tmp/midi_to_lilypond.py` - MIDI → LilyPond (notes/rhythms only)
- `tmp/musicxml_to_lilypond.py` - MusicXML → LilyPond (multi-part extraction)

See [MULTI_PART_SCORES.md](MULTI_PART_SCORES.md) for multi-part scores.
