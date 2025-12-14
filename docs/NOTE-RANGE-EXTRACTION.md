# Note Range Extraction

**Status:** Implemented. Using Eric's pre-parsed range output.

## How It Works

1. Eric runs LilyPond locally (generates PDFs + logs with ambitus data)
2. Eric runs `Wrappers/parse-log-ambitus.py` to parse the log
3. Eric commits `Wrappers/range-data.txt` to his repo
4. GitHub workflow runs `build_catalog.py --ranges-file` → reads the file → builds catalog

No LilyPond or MIDI parsing needed in CI. Fast builds.

## Files

- **Eric's repo:** `Wrappers/range-data.txt` - pre-parsed note ranges
- **Eric's repo:** `Wrappers/parse-log-ambitus.py` - script to generate range-data.txt
- **Jazz-picker:** `build_catalog.py --ranges-file PATH` - reads the ranges

## Range Data Format

```
502 Blues - Ly - Am Standard.ly
refrain
dis'
gis''

A Beautiful Friendship - Ly - C Standard.ly
refrain
b
d''
```

Four lines per section: filename, section name, low note (Dutch notation), high note. Blank line between entries.

## Dutch Notation → MIDI

- Notes: c=0, d=2, e=4, f=5, g=7, a=9, b=11
- Accidentals: `is`=+1 (sharp), `es`=-1 (flat)
- Octave: `'`=+12, `,`=-12
- Base: C (no marks) = MIDI 48

Examples: `c'`=60, `b`=59, `d''`=74, `fis'`=66, `bes`=58

## Usage

```bash
# With note ranges (recommended)
python build_catalog.py --ranges-file lilypond-data/Wrappers/range-data.txt

# Without note ranges (fast, for testing)
python build_catalog.py --skip-ranges

# Limit songs (for testing)
python build_catalog.py --ranges-file lilypond-data/Wrappers/range-data.txt --limit 10
```
