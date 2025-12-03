# Session Handoff - Dec 3, 2025

## Current Focus: Extracting Note Ranges via MIDI

### The Goal

Jazz Picker needs to set `whatKey` with correct octave markers (`,` or `'`) when generating bass clef PDFs. To do this, we need to know each song's **note range** (low note, high note).

### The Plan: Parse MIDI Files

**Why MIDI?** Eric's LilyPond workflow generates MIDI files via `midi.ily`. The melody is on an "overdriven guitar" track. MIDI has absolute pitches—no parsing drift issues like python-ly had.

### Validated Approach (Dec 3 - Session 4)

We tested and validated this approach on several songs:

| Song | Raw Range | After Filtering | Notes |
|------|-----------|-----------------|-------|
| 502 Blues | D#4-G#5 | D#4-G#5 | ✓ Verified against chart |
| Agua de Beber | F#3-A5 | G4-A5 | F#3, G3 are `\voiceTwo` bass fill |
| Song for My Father | F3-G5 | F3-G5 | Clean, no secondary voices |
| In Walked Bud | G#3-G#5 | G#3-G#5 | Clean |
| Sugar | F3-A#4 | ? | F3 from intro chord voicing |

**Key findings:**
- MIDI program 29 (0-indexed) = "overdriven guitar" = melody track
- MIDI program 16 = "drawbar organ" = chords track
- Some songs have `\voiceTwo` bass fills that appear in MIDI but should be excluded
- These outlier notes are typically >1 octave below the main melody range

### Implementation Steps

1. **Generate MIDI from Standard wrappers**
   ```bash
   lilypond --output=/tmp -dno-print-pages "Wrappers/Song - Ly - Key Standard.ly"
   ```
   - Use `-dno-print-pages` to skip PDF (faster, avoids LilyPond 2.24/2.25 compat issues)
   - Process only `*Standard.ly` files (one per song, no transpositions)

2. **Parse MIDI with mido**
   ```python
   import mido
   midi_file = mido.MidiFile(path)
   for track in midi_file.tracks:
       for msg in track:
           if msg.type == 'program_change':
               current_program = msg.program
           elif msg.type == 'note_on' and msg.velocity > 0:
               if current_program == 29:  # melody track
                   melody_notes.append(msg.note)
   ```

3. **Filter outliers (voiceTwo bass fills)**
   ```python
   import statistics
   median = statistics.median(melody_notes)
   # Exclude notes >12 semitones (1 octave) below median
   filtered = [n for n in melody_notes if n >= median - 12]
   low_note = min(filtered)
   high_note = max(filtered)
   ```

4. **Store in catalog.db**
   ```sql
   ALTER TABLE songs ADD COLUMN low_note_midi INTEGER;
   ALTER TABLE songs ADD COLUMN high_note_midi INTEGER;
   ```

5. **Use at PDF generation time** (`app.py`)
   ```python
   def calculate_bass_octave(low_note_midi, target_key):
       # Goal: lowest note no lower than E below bass staff (E2 = MIDI 40)
       low_e_midi = 40
       transposed_low = low_note_midi + key_semitone_offset(target_key)
       octave_offset = 0
       while transposed_low < low_e_midi:
           transposed_low += 12
           octave_offset += 1
       return octave_offset  # 0 = no marker, 1 = ",", 2 = ",,"
   ```

### Key Files

| File | Purpose |
|------|---------|
| `extract_note_ranges.py` | Proof-of-concept script (in jazz-picker root) |
| `lilypond-data/Include/midi.ily` | LilyPond MIDI generation |
| `lilypond-data/Include/refrain.ily:214` | Includes midi.ily |
| `build_catalog.py` | Integrate MIDI parsing here |
| `app.py:generate_wrapper_content()` | Use note range for octave calculation |

### Why Statistical Filtering Works

Some songs have `\voiceTwo` sections with bass fills (e.g., Agua de Beber measure ~20 has `g,8 fs8~`). These appear in the melody MIDI track but are secondary voices, often marked with `\magnifyMusic 0.63` (smaller notation).

We could parse LilyPond source to identify `\voiceTwo` notes, but that requires converting relative notation to absolute pitches—complex and error-prone.

**Simpler approach:** Filter notes >1 octave below the median. Bass fills are always significantly lower than the main melody, so statistical filtering catches them reliably. Not perfect, but good enough.

---

## Background: The bassKey Problem

Eric's LilyPond system uses two variables for transposition:
- `whatKey` - target key for melody (may include octave marker like `f,`)
- `bassKey` - target key for bass line (pitch class only, no octave marker)

### Rules (confirmed with Eric)

| Clef | whatKey | bassKey |
|------|---------|---------|
| Treble | `f` | `f` |
| Bass | `f,` (with octave marker) | `f` (pitch class only) |

The octave marker ensures the melody doesn't go below readable bass clef range.

---

## Quick Reference

### MIDI Note Numbers
```
C2 = 36, E2 = 40 (low E for bass clef target)
C3 = 48, C4 = 60 (middle C), C5 = 72, C6 = 84
```

### LilyPond Octave Notation
```
c, = C2    c = C3    c' = C4 (middle C)    c'' = C5
```

---

## Previous Sessions

### Dec 3 - Session 4 (This Session)
- Created `extract_note_ranges.py` proof-of-concept
- Validated MIDI parsing on 502 Blues, Agua de Beber, Song for My Father, In Walked Bud, Sugar
- Discovered `\voiceTwo` bass fills cause outlier low notes
- Decided on statistical filtering (>1 octave below median) as "good enough" solution
- Updated ROADMAP: offline caching moved to Paused

### Dec 3 - Session 3
- Abandoned python-ly approach (drift issues with repeated sections)
- New plan: Parse MIDI files generated by Eric's workflow

### Dec 3 - Sessions 1-2
- Discussed bassKey implementation with Eric
- Investigated python-ly (unreliable)

### Dec 2
- Spin roulette wheel feature
- PDF transition overlay
- PDF viewer race condition fix

---

## Current Stack

| Component | Location |
|-----------|----------|
| Web | jazzpicker.pianohouseproject.org (Vercel) |
| iOS | TestFlight (Jazz Picker) |
| Backend | jazz-picker.fly.dev (Fly.io) |
| PDFs | AWS S3 |
| LilyPond source | lilypond-data/ submodule |

## Quick Commands

```bash
# Test MIDI generation for a single song
cd lilypond-data
lilypond --output=/tmp -dno-print-pages "Wrappers/502 Blues - Ly - Am Standard.ly"

# Parse with Python
python3 -c "import mido; print(mido.MidiFile('/tmp/502 Blues - Ly - Am Standard.midi').tracks)"

# Run proof-of-concept on 5 songs
python3 extract_note_ranges.py --limit 5
```

## Next Steps

1. **Integrate MIDI parsing into `build_catalog.py`**
   - Add `low_note_midi`, `high_note_midi` columns
   - Process all ~735 Standard wrapper files
   - Apply statistical outlier filtering

2. **Update `app.py` to use note ranges**
   - Calculate octave marker for bass clef PDFs
   - Set `whatKey` and `bassKey` correctly

3. **Clear S3 cache after deployment**
   ```bash
   aws s3 rm s3://jazz-picker-pdfs/generated/ --recursive
   ```
