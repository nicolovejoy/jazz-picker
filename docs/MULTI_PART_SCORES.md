# Multi-Part Scores

MusicXML → LilyPond conversion for arrangements with separate instrument parts.

## Usage

```bash
source venv/bin/activate
python tools/musicxml_to_lilypond.py path/to/file.xml
```

Generates Core + Wrapper files in `custom-charts/`. Each part appears as a separate song in the catalog.

## Converter Features

- Chord symbol extraction from MusicXML harmony elements
- Repeat expansion (uses own logic, not music21's buggy `expandRepeats()`)
- Global pickup detection (consistent measure numbers across all parts)
- Rhythm slash detection (skips parts that are just strum patterns)
- Part name in subtitle
- Automatic clef selection (bass clef for low parts)
- Octave reference adjustment (`\relative f,` for bass, `\relative f` for guitar)

## Known Issues

- **LilyPond version**: lilypond-data submodule uses 2.25+ features. Local compilation requires LilyPond 2.25+; backend on Fly.io handles this.

## File Naming

- Core: `{Title} - Ly Core - {PartName} - {Key}.ly`
- Wrapper: `{Title} ({PartName}) - Ly - {Key} Standard.ly`

## UI Grouping

Multi-part scores are grouped in the iOS browse list:
- Parts share a `score_id` (the base song title) and have a `part_name`
- Browse list shows an expandable row: "My Window Faces the South (5 parts)"
- Expanding shows individual parts: "Lead", "Bass", "Violin", etc.
- Grid view remains flat (shows all parts as separate cards)

