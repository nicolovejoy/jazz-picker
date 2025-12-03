#!/usr/bin/env python3
"""
Extract note ranges from LilyPond files via MIDI generation.

This script:
1. Runs LilyPond on wrapper files to generate MIDI (skipping PDF output)
2. Parses MIDI files to extract melody note ranges
3. Outputs results as JSON

The melody is on the "overdriven guitar" track (MIDI program 29, 0-indexed).
"""

import subprocess
import os
import json
import tempfile
import re
from pathlib import Path

try:
    import mido
except ImportError:
    print("Error: mido not installed. Run: pip3 install mido")
    exit(1)


LILYPOND_DATA = Path(__file__).parent / "lilypond-data"
WRAPPERS_DIR = LILYPOND_DATA / "Wrappers"
MELODY_PROGRAM = 29  # "overdriven guitar" (0-indexed)


def midi_note_to_name(note: int) -> str:
    """Convert MIDI note number to note name (e.g., 60 -> 'C4')."""
    names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
    octave = (note // 12) - 1
    name = names[note % 12]
    return f"{name}{octave}"


def extract_song_title(wrapper_path: Path) -> str:
    """Extract song title from wrapper filename.

    Format: 'Song Title - Ly - Key Variant.ly'
    Returns: 'Song Title'
    """
    name = wrapper_path.stem  # Remove .ly extension
    match = re.match(r'^(.+?) - Ly - ', name)
    if match:
        return match.group(1)
    return name


def generate_midi(wrapper_path: Path, output_dir: Path) -> Path | None:
    """Run LilyPond to generate MIDI file.

    Returns path to generated MIDI file, or None on failure.
    """
    # LilyPond outputs to current directory with input filename
    midi_name = wrapper_path.stem + ".midi"
    output_path = output_dir / midi_name

    # Run lilypond with no PDF output
    cmd = [
        "lilypond",
        "--output=" + str(output_dir),
        "-dno-print-pages",  # Skip PDF generation
        str(wrapper_path)
    ]

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60,
            cwd=LILYPOND_DATA
        )

        # Check if MIDI was generated (lilypond may have warnings but still produce MIDI)
        if output_path.exists():
            return output_path
        else:
            print(f"  Warning: MIDI not generated for {wrapper_path.name}")
            return None

    except subprocess.TimeoutExpired:
        print(f"  Warning: Timeout generating MIDI for {wrapper_path.name}")
        return None
    except Exception as e:
        print(f"  Warning: Error generating MIDI for {wrapper_path.name}: {e}")
        return None


def parse_midi_note_range(midi_path: Path) -> tuple[int, int] | None:
    """Parse MIDI file and extract melody note range.

    Returns (low_note, high_note) as MIDI numbers, or None if no melody found.

    Applies statistical filtering to exclude outlier bass fills from \voiceTwo
    sections (notes >12 semitones below median are excluded).
    """
    import statistics

    try:
        midi_file = mido.MidiFile(str(midi_path))

        # Find the melody track (program 29 = overdriven guitar)
        melody_notes = []

        for track in midi_file.tracks:
            current_program = None
            for msg in track:
                if msg.type == 'program_change':
                    current_program = msg.program
                elif msg.type == 'note_on' and msg.velocity > 0:
                    # Check if this is the melody track
                    if current_program == MELODY_PROGRAM:
                        melody_notes.append(msg.note)

        if melody_notes:
            # Filter outliers: exclude notes >12 semitones (1 octave) below median
            # This removes \voiceTwo bass fills while keeping the main melody
            median = statistics.median(melody_notes)
            filtered = [n for n in melody_notes if n >= median - 12]

            if filtered:
                return (min(filtered), max(filtered))
            return (min(melody_notes), max(melody_notes))

        # Fallback: if no program 29 found, try the last track with notes
        for track in reversed(midi_file.tracks):
            notes = [msg.note for msg in track if msg.type == 'note_on' and msg.velocity > 0]
            if notes:
                median = statistics.median(notes)
                filtered = [n for n in notes if n >= median - 12]
                if filtered:
                    return (min(filtered), max(filtered))
                return (min(notes), max(notes))

        return None

    except Exception as e:
        print(f"  Warning: Error parsing MIDI {midi_path.name}: {e}")
        return None


def process_wrapper(wrapper_path: Path, output_dir: Path) -> dict | None:
    """Process a single wrapper file and extract note range.

    Returns dict with song info, or None on failure.
    """
    song_title = extract_song_title(wrapper_path)

    # Generate MIDI
    midi_path = generate_midi(wrapper_path, output_dir)
    if not midi_path:
        return None

    # Parse note range
    note_range = parse_midi_note_range(midi_path)
    if not note_range:
        return None

    low_note, high_note = note_range

    return {
        "title": song_title,
        "wrapper": wrapper_path.name,
        "low_note_midi": low_note,
        "high_note_midi": high_note,
        "low_note_name": midi_note_to_name(low_note),
        "high_note_name": midi_note_to_name(high_note),
    }


def get_standard_wrappers() -> list[Path]:
    """Get list of Standard wrapper files (one per song, no transpositions).

    Filters for files ending in exactly " Standard.ly" (not "Bass for Standard.ly").
    """
    wrappers = []
    for f in WRAPPERS_DIR.glob("*Standard.ly"):
        # Must end with exactly " Standard.ly" (excludes "Bass for Standard.ly", etc.)
        if f.name.endswith(" Standard.ly") and " for Standard.ly" not in f.name:
            wrappers.append(f)
    return sorted(wrappers)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Extract note ranges from LilyPond files via MIDI")
    parser.add_argument("--limit", type=int, help="Limit number of files to process (for testing)")
    parser.add_argument("--output", type=str, default="note_ranges.json", help="Output JSON file")
    parser.add_argument("--all", action="store_true", help="Process all wrappers (not just Standard)")
    args = parser.parse_args()

    # Get wrapper files
    if args.all:
        wrappers = sorted(WRAPPERS_DIR.glob("*.ly"))
    else:
        wrappers = get_standard_wrappers()

    if args.limit:
        wrappers = wrappers[:args.limit]

    print(f"Processing {len(wrappers)} wrapper files...")

    # Create temp directory for MIDI files
    with tempfile.TemporaryDirectory() as temp_dir:
        output_dir = Path(temp_dir)

        results = []
        seen_titles = set()

        for i, wrapper in enumerate(wrappers, 1):
            print(f"[{i}/{len(wrappers)}] {wrapper.name}")

            result = process_wrapper(wrapper, output_dir)
            if result:
                # Only keep one entry per song title
                if result["title"] not in seen_titles:
                    results.append(result)
                    seen_titles.add(result["title"])
                    print(f"  -> {result['low_note_name']} ({result['low_note_midi']}) to {result['high_note_name']} ({result['high_note_midi']})")

    # Write results
    with open(args.output, 'w') as f:
        json.dump(results, f, indent=2)

    print(f"\nWrote {len(results)} song ranges to {args.output}")


if __name__ == "__main__":
    main()
