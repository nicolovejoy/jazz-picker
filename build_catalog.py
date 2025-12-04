#!/usr/bin/env python3
"""
Build Jazz Picker catalog from LilyPond wrapper files.

This script:
1. Scans lilypond-data/Wrappers/*.ly files
2. Extracts song title, default key, and core file references
3. Generates MIDI via LilyPond to extract note ranges
4. Stores everything in catalog.db (SQLite)

Usage:
    python build_catalog.py                    # Full build with MIDI
    python build_catalog.py --skip-midi        # Skip MIDI generation (faster, no note ranges)
    python build_catalog.py --limit 10         # Process only 10 songs (for testing)
"""

import sqlite3
import subprocess
import os
import re
import tempfile
import statistics
from pathlib import Path
from datetime import datetime

# =============================================================================
# CONFIGURATION
# =============================================================================

# Outlier threshold: notes more than this many semitones below the median
# are considered bass fills from \voiceTwo and excluded from the melody range.
# 12 semitones = 1 octave
OUTLIER_THRESHOLD_SEMITONES = 12

# MIDI program numbers (0-indexed)
MELODY_PROGRAM = 29  # "overdriven guitar" in Eric's midi.ily

# Paths
LILYPOND_DATA = Path(__file__).parent / "lilypond-data"
WRAPPERS_DIR = LILYPOND_DATA / "Wrappers"
CATALOG_DB = Path(__file__).parent / "catalog.db"
OUTLIER_REPORT = Path(__file__).parent / "outlier_report.txt"

# =============================================================================
# MIDI PARSING (requires mido)
# =============================================================================

def midi_note_to_name(note: int) -> str:
    """Convert MIDI note number to note name (e.g., 60 -> 'C4')."""
    names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
    octave = (note // 12) - 1
    name = names[note % 12]
    return f"{name}{octave}"


def generate_midi(wrapper_path: Path, output_dir: Path) -> Path:
    """
    Run LilyPond to generate MIDI file.

    Returns path to generated MIDI file.
    Raises RuntimeError on failure.
    """
    midi_name = wrapper_path.stem + ".midi"
    output_path = output_dir / midi_name

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
            timeout=120,
            cwd=LILYPOND_DATA
        )

        if output_path.exists():
            return output_path
        else:
            raise RuntimeError(
                f"LilyPond did not generate MIDI.\n"
                f"stdout: {result.stdout[-500:] if result.stdout else '(empty)'}\n"
                f"stderr: {result.stderr[-500:] if result.stderr else '(empty)'}"
            )

    except subprocess.TimeoutExpired:
        raise RuntimeError("LilyPond timed out after 120 seconds")


def parse_midi_note_range(midi_path: Path) -> tuple[int, int, list[int]]:
    """
    Parse MIDI file and extract melody note range.

    Returns (low_note, high_note, filtered_out_notes) as MIDI numbers.
    filtered_out_notes contains any notes that were excluded by outlier filtering.

    Raises RuntimeError if no melody notes found.
    """
    import mido

    midi_file = mido.MidiFile(str(midi_path))

    # Find the melody track (program 29 = overdriven guitar)
    melody_notes = []

    for track in midi_file.tracks:
        current_program = None
        for msg in track:
            if msg.type == 'program_change':
                current_program = msg.program
            elif msg.type == 'note_on' and msg.velocity > 0:
                if current_program == MELODY_PROGRAM:
                    melody_notes.append(msg.note)

    if not melody_notes:
        # Fallback: try the last track with notes
        for track in reversed(midi_file.tracks):
            notes = [msg.note for msg in track if msg.type == 'note_on' and msg.velocity > 0]
            if notes:
                melody_notes = notes
                break

    if not melody_notes:
        raise RuntimeError("No melody notes found in MIDI file")

    # Filter outliers: exclude notes > threshold below median
    median = statistics.median(melody_notes)
    threshold = median - OUTLIER_THRESHOLD_SEMITONES

    filtered = [n for n in melody_notes if n >= threshold]
    filtered_out = sorted(set(n for n in melody_notes if n < threshold))

    if not filtered:
        # Should never happen, but fall back to unfiltered
        filtered = melody_notes
        filtered_out = []

    return (min(filtered), max(filtered), filtered_out)


# =============================================================================
# WRAPPER FILE PARSING
# =============================================================================

def extract_song_info(wrapper_path: Path) -> dict:
    """
    Extract song info from wrapper filename and content.

    Filename format: 'Song Title - Ly - Key Variant.ly'
    Returns: {'title': str, 'default_key': str, 'core_files': list[str]}
    """
    name = wrapper_path.stem  # Remove .ly extension

    # Parse filename
    match = re.match(r'^(.+?) - Ly - ([A-Ga-g][#bsf]?m?)(?:\s|$)', name)
    if not match:
        raise ValueError(f"Cannot parse wrapper filename: {name}")

    title = match.group(1)
    default_key = match.group(2).lower()

    # Normalize key format to LilyPond notation:
    # - Strip 'm' suffix (minor keys just use pitch class)
    # - Convert 'b' flat notation to 'f' (e.g., 'bb' -> 'bf', 'eb' -> 'ef')
    # - Convert '#' sharp to 's' (e.g., 'f#' -> 'fs')
    default_key = default_key.rstrip('m')  # Remove minor indicator
    default_key = default_key.replace('#', 's')  # Sharp notation
    # Convert flat notation: 'xb' -> 'xf' (but not 'b' alone which is B natural)
    if len(default_key) == 2 and default_key[1] == 'b':
        default_key = default_key[0] + 'f'

    # Extract core file references from content
    content = wrapper_path.read_text()
    core_files = re.findall(r'\\include\s+"\.\.\/Core\/([^"]+)"', content)

    return {
        'title': title,
        'default_key': default_key,
        'core_files': core_files,
    }


def get_standard_wrappers() -> list[Path]:
    """
    Get list of Standard wrapper files (one per song, no transpositions).

    Filters for files ending in exactly " Standard.ly" (not "Bass for Standard.ly").
    """
    wrappers = []
    for f in WRAPPERS_DIR.glob("*Standard.ly"):
        # Must end with exactly " Standard.ly" (excludes "Bass for Standard.ly", etc.)
        if f.name.endswith(" Standard.ly") and " for Standard.ly" not in f.name:
            wrappers.append(f)
    return sorted(wrappers)


# =============================================================================
# DATABASE
# =============================================================================

def create_database(db_path: Path) -> sqlite3.Connection:
    """Create fresh database with schema."""
    # Remove existing database
    if db_path.exists():
        db_path.unlink()

    conn = sqlite3.connect(db_path)

    conn.executescript("""
        CREATE TABLE songs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT UNIQUE NOT NULL,
            default_key TEXT DEFAULT 'c',
            core_files TEXT,
            low_note_midi INTEGER,
            high_note_midi INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX idx_songs_title ON songs(title);

        CREATE TABLE metadata (
            key TEXT PRIMARY KEY,
            value TEXT
        );
    """)

    return conn


def insert_song(conn: sqlite3.Connection, song: dict):
    """Insert a song into the database."""
    import json

    conn.execute("""
        INSERT INTO songs (title, default_key, core_files, low_note_midi, high_note_midi)
        VALUES (?, ?, ?, ?, ?)
    """, (
        song['title'],
        song['default_key'],
        json.dumps(song.get('core_files', [])),
        song.get('low_note_midi'),
        song.get('high_note_midi'),
    ))


# =============================================================================
# MAIN
# =============================================================================

def main():
    import argparse

    parser = argparse.ArgumentParser(description="Build Jazz Picker catalog from LilyPond files")
    parser.add_argument("--skip-midi", action="store_true", help="Skip MIDI generation (no note ranges)")
    parser.add_argument("--limit", type=int, help="Limit number of songs to process (for testing)")
    parser.add_argument("--output", type=str, default=str(CATALOG_DB), help="Output database path")
    args = parser.parse_args()

    # Check for mido if we need MIDI
    if not args.skip_midi:
        try:
            import mido
        except ImportError:
            print("Error: mido not installed. Run: pip3 install mido")
            print("Or use --skip-midi to skip note range extraction.")
            exit(1)

    # Check lilypond-data exists
    if not WRAPPERS_DIR.exists():
        print(f"Error: lilypond-data not found at {LILYPOND_DATA}")
        print("Make sure the lilypond-data submodule is initialized.")
        exit(1)

    # Get wrapper files
    wrappers = get_standard_wrappers()
    if args.limit:
        wrappers = wrappers[:args.limit]

    print(f"Processing {len(wrappers)} Standard wrapper files...")

    # Create database
    db_path = Path(args.output)
    conn = create_database(db_path)

    # Track outliers for report
    outlier_report = []
    errors = []
    seen_titles = set()  # Skip duplicate song titles

    # Create temp directory for MIDI files
    with tempfile.TemporaryDirectory() as temp_dir:
        output_dir = Path(temp_dir)

        for i, wrapper in enumerate(wrappers, 1):
            print(f"[{i}/{len(wrappers)}] {wrapper.name}")

            try:
                # Extract song info from wrapper
                song = extract_song_info(wrapper)

                # Skip duplicate song titles (some songs have multiple Standard versions in different keys)
                if song['title'] in seen_titles:
                    print(f"  -> skipping (duplicate title)")
                    continue
                seen_titles.add(song['title'])

                # Generate MIDI and extract note range
                if not args.skip_midi:
                    midi_path = generate_midi(wrapper, output_dir)
                    low, high, filtered_out = parse_midi_note_range(midi_path)

                    song['low_note_midi'] = low
                    song['high_note_midi'] = high

                    print(f"  -> {midi_note_to_name(low)} to {midi_note_to_name(high)}")

                    # Record outliers
                    if filtered_out:
                        outlier_report.append({
                            'title': song['title'],
                            'wrapper': wrapper.name,
                            'filtered_notes': [midi_note_to_name(n) for n in filtered_out],
                            'kept_range': f"{midi_note_to_name(low)} - {midi_note_to_name(high)}",
                        })
                        print(f"  -> OUTLIERS FILTERED: {[midi_note_to_name(n) for n in filtered_out]}")

                    # Clean up MIDI file
                    midi_path.unlink()

                # Insert into database
                insert_song(conn, song)

            except Exception as e:
                error_msg = f"FAILED: {wrapper.name} - {e}"
                print(f"  -> {error_msg}")
                errors.append(error_msg)

    # Add metadata
    conn.execute("INSERT INTO metadata (key, value) VALUES (?, ?)",
                 ('built_at', datetime.now().isoformat()))
    conn.execute("INSERT INTO metadata (key, value) VALUES (?, ?)",
                 ('song_count', str(len(seen_titles))))
    conn.execute("INSERT INTO metadata (key, value) VALUES (?, ?)",
                 ('outlier_threshold_semitones', str(OUTLIER_THRESHOLD_SEMITONES)))

    conn.commit()
    conn.close()

    # Write outlier report
    if outlier_report:
        with open(OUTLIER_REPORT, 'w') as f:
            f.write(f"Outlier Report - {datetime.now().isoformat()}\n")
            f.write(f"Threshold: {OUTLIER_THRESHOLD_SEMITONES} semitones below median\n")
            f.write("=" * 60 + "\n\n")

            for entry in outlier_report:
                f.write(f"Song: {entry['title']}\n")
                f.write(f"Wrapper: {entry['wrapper']}\n")
                f.write(f"Filtered notes: {', '.join(entry['filtered_notes'])}\n")
                f.write(f"Kept range: {entry['kept_range']}\n")
                f.write("-" * 40 + "\n")

        print(f"\nOutlier report written to: {OUTLIER_REPORT}")
        print(f"  {len(outlier_report)} songs had notes filtered out")

    # Report results
    print(f"\nCatalog built: {db_path}")
    print(f"  Songs: {len(seen_titles)}")

    # Fail on errors
    if errors:
        print(f"\n{'='*60}")
        print(f"BUILD FAILED - {len(errors)} error(s):")
        print("=" * 60)
        for err in errors:
            print(f"  {err}")
        exit(1)

    print("\nBuild completed successfully!")


if __name__ == "__main__":
    main()
