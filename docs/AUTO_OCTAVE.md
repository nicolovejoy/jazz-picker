# Auto-Octave Calculation

When generating a PDF, the backend automatically calculates the optimal octave offset so the melody fits within the instrument's playable range.

## How It Works

1. Get song's MIDI note range from database
2. Apply key transposition (semitones from default to target key)
3. Apply instrument transposition (C=0, Bb=+2, Eb=+9 semitones)
4. For each octave offset (-2 to +2), calculate % overlap with instrument range
5. Return the offset with highest overlap

## Supported Instruments

| Instrument   | Transposition | Clef   | Written Range | MIDI    |
|--------------|---------------|--------|---------------|---------|
| Trumpet      | Bb            | treble | F#3-C6        | 54-84   |
| Clarinet     | Bb            | treble | E3-G6         | 52-91   |
| Tenor Sax    | Bb            | treble | Bb3-F6        | 58-89   |
| Alto Sax     | Eb            | treble | Bb3-F6        | 58-89   |
| Soprano Sax  | Bb            | treble | Bb3-F6        | 58-89   |
| Bari Sax     | Eb            | treble | Bb3-F6        | 58-89   |
| Trombone     | C             | bass   | E2-Bb4        | 40-70   |
| Flute        | C             | treble | C4-C7         | 60-96   |
| Piano        | C             | treble | (no limit)    | -       |
| Guitar       | C             | treble | (no limit)    | -       |
| Bass         | C             | bass   | (no limit)    | -       |

## API Usage

The `/api/v2/generate` endpoint auto-calculates octave when `instrument_label` is provided:

```json
POST /api/v2/generate
{
    "song": "502 Blues",
    "concert_key": "ef",
    "transposition": "Bb",
    "clef": "treble",
    "instrument_label": "Trumpet"
}
```

Response includes the calculated offset:

```json
{
    "url": "https://...",
    "octave_offset": 0
}
```

To override auto-calculation, explicitly pass `octave_offset`:

```json
{
    "song": "502 Blues",
    "concert_key": "ef",
    "transposition": "Bb",
    "clef": "treble",
    "instrument_label": "Trumpet",
    "octave_offset": -1
}
```

## Edge Cases

- **No note range data**: Returns 0 (no adjustment)
- **Unknown instrument**: Returns 0
- **Piano/Guitar/Bass**: Always returns 0 (no range limits)
- **No perfect fit**: Picks best available offset
