# Note Range Extraction

Eric's `ambitus-engraver.ily` outputs note ranges to LilyPond logs. His `parse-log-ambitus.py` script parses these into `range-data.txt`.

## Usage

```bash
python build_catalog.py --ranges-file lilypond-data/Wrappers/range-data.txt
```

## Range Data Format

```
Song Title - Ly - Key Standard.ly
refrain
dis'
gis''
```

Four lines per section: filename, section name, low note (Dutch notation), high note.

## Dutch Notation → MIDI

- Notes: c=0, d=2, e=4, f=5, g=7, a=9, b=11
- Accidentals: `is`=+1 (sharp), `es`=-1 (flat)
- Octave: `'`=+12, `,`=-12
- Base: C (no marks) = MIDI 48

Examples: `c'`=60, `fis'`=66, `bes`=58
