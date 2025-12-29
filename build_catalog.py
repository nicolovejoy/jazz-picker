#!/usr/bin/env python3
"""
Build Jazz Picker catalog from LilyPond wrapper files.

This script:
1. Scans lilypond-data/Wrappers/*.ly files
2. Extracts song title, default key, and core file references
3. Reads note ranges from pre-parsed range file (or generates via MIDI)
4. Stores everything in catalog.db (SQLite)

Usage:
    python build_catalog.py --ranges-file PATH  # Read ranges from Eric's parsed output (recommended)
    python build_catalog.py --skip-ranges       # Skip note ranges entirely (fast, no ranges)
    python build_catalog.py --limit 10          # Process only 10 songs (for testing)
    python build_catalog.py --custom-dir PATH   # Include custom charts from PATH/Wrappers/
"""

import sqlite3
import os
import re
import subprocess
import hashlib
import json
from pathlib import Path
from datetime import datetime

# =============================================================================
# CONFIGURATION
# =============================================================================

# Paths
LILYPOND_DATA = Path(__file__).parent / "lilypond-data"
WRAPPERS_DIR = LILYPOND_DATA / "Wrappers"
CATALOG_DB = Path(__file__).parent / "catalog.db"

# =============================================================================
# CACHE INVALIDATION - Git dates and Include versioning
# =============================================================================

def get_git_commit_date(file_path: Path) -> str | None:
    """
    Get the ISO timestamp of the last git commit that modified a file.
    Returns None if file is not in git or git command fails.

    Runs git from the file's directory to handle submodules correctly.
    """
    try:
        # Run git from the file's directory (important for submodules)
        result = subprocess.run(
            ['git', 'log', '-1', '--format=%cI', '--', file_path.name],
            capture_output=True,
            text=True,
            timeout=5,
            cwd=file_path.parent
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return None


def compute_include_version(include_dir: Path) -> str:
    """
    Compute a hash of all Include/*.ily files for cache invalidation.
    Returns first 12 chars of SHA256 hash.
    """
    if not include_dir.exists():
        return "unknown"

    hasher = hashlib.sha256()

    # Sort files for deterministic ordering
    ily_files = sorted(include_dir.glob("*.ily"))

    for f in ily_files:
        # Hash filename and content
        hasher.update(f.name.encode())
        hasher.update(f.read_bytes())

    return hasher.hexdigest()[:12]

# =============================================================================
# RANGE FILE PARSING (Eric's parsed ambitus output)
# =============================================================================

def dutch_note_to_midi(note_str: str) -> int:
    """
    Convert Dutch LilyPond notation to MIDI note number.

    Format: [note][accidental][octave_marks]
    - Notes: c=0, d=2, e=4, f=5, g=7, a=9, b=11
    - Accidentals: 'is'=+1 (sharp), 'es'=-1 (flat), 'isis'=+2, 'eses'=-2
    - Octave: each "'" = +12, each "," = -12
    - Base: C (no marks) = MIDI 48 (C3)

    Examples: c'=60, b=59, d''=74, fis'=66, bes=58
    """
    NOTE_VALUES = {'c': 0, 'd': 2, 'e': 4, 'f': 5, 'g': 7, 'a': 9, 'b': 11}
    BASE_OCTAVE = 48  # C with no octave marks = MIDI 48 (C3)

    if not note_str or note_str == 'none':
        return None

    note_str = note_str.strip()

    # Extract base note (first character)
    base_note = note_str[0].lower()
    if base_note not in NOTE_VALUES:
        raise ValueError(f"Invalid note: {note_str}")

    midi = BASE_OCTAVE + NOTE_VALUES[base_note]

    # Process rest of string for accidentals and octave marks
    rest = note_str[1:]

    # Count accidentals (Dutch: is=sharp, es=flat)
    # Handle 'isis', 'eses', 'is', 'es'
    while rest.startswith('isis'):
        midi += 2
        rest = rest[4:]
    while rest.startswith('eses'):
        midi -= 2
        rest = rest[4:]
    while rest.startswith('is'):
        midi += 1
        rest = rest[2:]
    while rest.startswith('es'):
        midi -= 1
        rest = rest[2:]
    # Handle 'as' as A-flat (Dutch quirk: aes -> as)
    if base_note == 'a' and note_str[1:].startswith('s') and not note_str[1:].startswith('is'):
        # 'as' means A-flat in Dutch
        midi -= 1
        rest = rest[1:] if rest.startswith('s') else rest

    # Count octave marks
    midi += rest.count("'") * 12
    midi -= rest.count(",") * 12

    return midi


def parse_ranges_file(filepath: Path) -> dict[str, tuple[int, int]]:
    """
    Parse Eric's range-data.txt file.

    Format (4 lines per entry, blank line between entries):
        filename.ly
        section_name
        low_note (Dutch notation)
        high_note (Dutch notation)

    Returns dict mapping filename -> (low_midi, high_midi).
    For files with multiple sections, returns overall min/max.
    """
    ranges = {}

    content = filepath.read_text()
    entries = content.strip().split('\n\n')

    for entry in entries:
        lines = entry.strip().split('\n')
        if len(lines) < 4:
            continue

        filename = lines[0].strip()
        # section = lines[1].strip()  # Not used, we combine sections
        low_str = lines[2].strip()
        high_str = lines[3].strip()

        if low_str == 'none' or high_str == 'none':
            continue

        try:
            low_midi = dutch_note_to_midi(low_str)
            high_midi = dutch_note_to_midi(high_str)
        except ValueError as e:
            print(f"  Warning: Could not parse range for {filename}: {e}")
            continue

        if low_midi is None or high_midi is None:
            continue

        # Combine with existing (for multi-section files)
        if filename in ranges:
            existing_low, existing_high = ranges[filename]
            ranges[filename] = (min(existing_low, low_midi), max(existing_high, high_midi))
        else:
            ranges[filename] = (low_midi, high_midi)

    return ranges

def midi_note_to_name(note: int) -> str:
    """Convert MIDI note number to note name (e.g., 60 -> 'C4')."""
    names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
    octave = (note // 12) - 1
    name = names[note % 12]
    return f"{name}{octave}"


# =============================================================================
# WRAPPER FILE PARSING
# =============================================================================

def extract_composer_from_core(core_filename: str) -> str | None:
    """
    Extract composer from a Core LilyPond file's header block.

    Returns composer name or None if not found.
    """
    core_path = LILYPOND_DATA / "Core" / core_filename
    if not core_path.exists():
        return None

    content = core_path.read_text()

    # Match: composer = "Name" or composer = "Name Name"
    match = re.search(r'composer\s*=\s*"([^"]+)"', content)
    if match:
        return match.group(1)

    return None


def extract_song_info(wrapper_path: Path, core_dir: Path = None) -> dict:
    """
    Extract song info from wrapper filename and content.

    Filename format: 'Song Title - Ly - Key Variant.ly'
    Returns: {'title': str, 'default_key': str, 'core_files': list[str], 'composer': str|None, 'core_modified': str|None}

    Args:
        wrapper_path: Path to the wrapper .ly file
        core_dir: Directory containing Core files (for git date lookup)
    """
    name = wrapper_path.stem  # Remove .ly extension

    # Parse filename
    match = re.match(r'^(.+?) - Ly - ([A-Ga-g][#bsf]?m?)(?:\s|$)', name)
    if not match:
        raise ValueError(f"Cannot parse wrapper filename: {name}")

    title = match.group(1)
    default_key = match.group(2).lower()

    # Normalize key format to LilyPond notation:
    # - Keep 'm' suffix for minor keys (e.g., 'am', 'bfm')
    # - Convert '#' sharp to 's' (e.g., 'f#' -> 'fs', 'f#m' -> 'fsm')
    # - Convert 'b' flat to 'f' (e.g., 'bb' -> 'bf', 'bbm' -> 'bfm')
    default_key = default_key.replace('#', 's')  # Sharp notation
    # Convert flat notation: 'xb' or 'xbm' -> 'xf' or 'xfm'
    if len(default_key) >= 2 and default_key[1] == 'b':
        if len(default_key) == 2 or default_key[2:] == 'm':
            default_key = default_key[0] + 'f' + default_key[2:]

    # Extract core file references from content
    content = wrapper_path.read_text()
    core_files = re.findall(r'\\include\s+"\.\.\/Core\/([^"]+)"', content)

    # Extract composer from first core file
    composer = None
    core_modified = None
    if core_files:
        composer = extract_composer_from_core(core_files[0])
        # Get git commit date for core file
        if core_dir:
            core_path = core_dir / core_files[0]
            if core_path.exists():
                core_modified = get_git_commit_date(core_path)

    return {
        'title': title,
        'default_key': default_key,
        'core_files': core_files,
        'composer': composer,
        'core_modified': core_modified,
    }


def get_standard_wrappers(wrappers_dir: Path = WRAPPERS_DIR) -> list[Path]:
    """
    Get list of Standard wrapper files (one per song, no transpositions).

    Filters for files ending in exactly " Standard.ly" (not "Bass for Standard.ly").
    """
    wrappers = []
    for f in wrappers_dir.glob("*Standard.ly"):
        # Must end with exactly " Standard.ly" (excludes "Bass for Standard.ly", etc.)
        if f.name.endswith(" Standard.ly") and " for Standard.ly" not in f.name:
            wrappers.append(f)
    return sorted(wrappers)


# =============================================================================
# MULTI-PART SCORE DETECTION
# =============================================================================

# Known part name patterns (case-insensitive match)
PART_PATTERNS = [
    'Lead', 'Bass', 'Violin', 'Violin 2', 'Guitar', 'Clean Electric Guitar',
    'Trumpet', 'Alto Sax', 'Tenor Sax', 'Trombone', 'Piano', 'Drums',
    'Flute', 'Clarinet', 'Cello', 'Viola', 'Horn', 'Keyboard',
]


def parse_part_from_title(title: str) -> tuple[str | None, str | None]:
    """
    Parse a title to extract score_id and part_name.

    Titles like "My Window Faces the South (Bass)" become:
      score_id = "My Window Faces the South"
      part_name = "Bass"

    Titles without recognized part patterns return (None, None).
    Titles with parentheticals that aren't part names (e.g., "Once I Loved (Amor Em Paz)")
    also return (None, None).
    """
    # Match trailing parenthetical: "Title (Part Name)"
    match = re.match(r'^(.+?)\s+\(([^)]+)\)$', title)
    if not match:
        return None, None

    base_title = match.group(1)
    candidate_part = match.group(2)

    # Check if the parenthetical looks like a part name
    # Either matches known patterns or contains instrument-like words
    candidate_lower = candidate_part.lower()

    for pattern in PART_PATTERNS:
        if candidate_lower == pattern.lower():
            return base_title, candidate_part

    # Additional heuristics: contains numbers like "Violin 2" or short instrument names
    if re.match(r'^[A-Z][a-z]+(\s+\d+)?$', candidate_part):
        # Could be an instrument - but be conservative
        # Only treat as part if there are other songs with same base title
        # For now, return None - we'll do a second pass
        pass

    return None, None


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
            composer TEXT,
            core_files TEXT,
            low_note_midi INTEGER,
            high_note_midi INTEGER,
            source TEXT DEFAULT 'standard',
            core_modified TEXT,
            score_id TEXT,
            part_name TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX idx_songs_title ON songs(title);
        CREATE INDEX idx_songs_composer ON songs(composer);
        CREATE INDEX idx_songs_source ON songs(source);
        CREATE INDEX idx_songs_score_id ON songs(score_id);

        CREATE TABLE metadata (
            key TEXT PRIMARY KEY,
            value TEXT
        );
    """)

    return conn


def insert_song(conn: sqlite3.Connection, song: dict, source: str = 'standard'):
    """Insert a song into the database."""
    # Parse part info from title
    score_id, part_name = parse_part_from_title(song['title'])

    conn.execute("""
        INSERT INTO songs (title, default_key, composer, core_files, low_note_midi, high_note_midi, source, core_modified, score_id, part_name)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        song['title'],
        song['default_key'],
        song.get('composer'),
        json.dumps(song.get('core_files', [])),
        song.get('low_note_midi'),
        song.get('high_note_midi'),
        source,
        song.get('core_modified'),
        score_id,
        part_name,
    ))


# =============================================================================
# MAIN
# =============================================================================

def main():
    import argparse

    parser = argparse.ArgumentParser(description="Build Jazz Picker catalog from LilyPond files")
    parser.add_argument("--ranges-file", type=str, help="Path to Eric's parsed range-data.txt file")
    parser.add_argument("--skip-ranges", action="store_true", help="Skip note ranges entirely")
    parser.add_argument("--limit", type=int, help="Limit number of songs to process (for testing)")
    parser.add_argument("--output", type=str, default=str(CATALOG_DB), help="Output database path")
    parser.add_argument("--custom-dir", type=str, help="Path to custom charts directory (e.g., custom-charts)")
    args = parser.parse_args()

    # Check lilypond-data exists
    if not WRAPPERS_DIR.exists():
        print(f"Error: lilypond-data not found at {LILYPOND_DATA}")
        print("Make sure the lilypond-data submodule is initialized.")
        exit(1)

    # Load ranges from file if provided
    ranges = {}
    if args.ranges_file:
        ranges_path = Path(args.ranges_file)
        if not ranges_path.exists():
            print(f"Error: Ranges file not found: {ranges_path}")
            exit(1)
        print(f"Loading note ranges from: {ranges_path}")
        ranges = parse_ranges_file(ranges_path)
        print(f"  Loaded ranges for {len(ranges)} files")

    # Get wrapper files
    wrappers = get_standard_wrappers()
    if args.limit:
        wrappers = wrappers[:args.limit]

    print(f"Processing {len(wrappers)} Standard wrapper files...")

    # Create database
    db_path = Path(args.output)
    conn = create_database(db_path)

    # Compute includeVersion for standard charts (Eric's lilypond-data/Include/)
    include_dir = LILYPOND_DATA / "Include"
    standard_include_version = compute_include_version(include_dir)
    print(f"Standard includeVersion: {standard_include_version}")

    # Standard Core directory
    standard_core_dir = LILYPOND_DATA / "Core"

    errors = []
    seen_titles = set()  # Skip duplicate song titles
    songs_with_ranges = 0

    for i, wrapper in enumerate(wrappers, 1):
        try:
            # Extract song info from wrapper
            song = extract_song_info(wrapper, core_dir=standard_core_dir)

            # Skip duplicate song titles (some songs have multiple Standard versions in different keys)
            if song['title'] in seen_titles:
                continue
            seen_titles.add(song['title'])

            # Look up note range from ranges file
            if not args.skip_ranges and wrapper.name in ranges:
                low, high = ranges[wrapper.name]
                song['low_note_midi'] = low
                song['high_note_midi'] = high
                songs_with_ranges += 1
                print(f"[{i}/{len(wrappers)}] {song['title']} -> {midi_note_to_name(low)} to {midi_note_to_name(high)}")
            else:
                print(f"[{i}/{len(wrappers)}] {song['title']}")

            # Insert into database
            insert_song(conn, song, source='standard')

        except Exception as e:
            error_msg = f"FAILED: {wrapper.name} - {e}"
            print(f"  -> {error_msg}")
            errors.append(error_msg)

    # Process custom charts if --custom-dir provided
    custom_count = 0
    custom_include_version = None
    if args.custom_dir:
        custom_dir = Path(args.custom_dir)
        custom_wrappers_dir = custom_dir / "Wrappers"
        custom_core_dir = custom_dir / "Core"

        # Custom charts use the same Include files as standard (for now)
        # In future, could have per-provider includes
        custom_include_version = standard_include_version

        if custom_wrappers_dir.exists():
            custom_wrappers = get_standard_wrappers(custom_wrappers_dir)
            print(f"\nProcessing {len(custom_wrappers)} custom wrapper files from {custom_wrappers_dir}...")

            for wrapper in custom_wrappers:
                try:
                    song = extract_song_info(wrapper, core_dir=custom_core_dir)

                    # Skip if title already exists (standard charts take precedence)
                    if song['title'] in seen_titles:
                        print(f"  Skipping duplicate: {song['title']}")
                        continue
                    seen_titles.add(song['title'])

                    # Custom charts don't have note ranges (yet)
                    print(f"[custom] {song['title']}")

                    insert_song(conn, song, source='custom')
                    custom_count += 1

                except Exception as e:
                    error_msg = f"FAILED (custom): {wrapper.name} - {e}"
                    print(f"  -> {error_msg}")
                    errors.append(error_msg)
        else:
            print(f"Warning: Custom wrappers directory not found: {custom_wrappers_dir}")

    # Add metadata
    conn.execute("INSERT INTO metadata (key, value) VALUES (?, ?)",
                 ('built_at', datetime.now().isoformat()))
    conn.execute("INSERT INTO metadata (key, value) VALUES (?, ?)",
                 ('song_count', str(len(seen_titles))))

    # Store providers with includeVersion for cache invalidation
    providers = {
        'standard': {
            'id': 'standard',
            'name': 'Eric Royer',
            'includeVersion': standard_include_version,
        }
    }
    if custom_include_version:
        providers['custom'] = {
            'id': 'custom',
            'name': 'Custom Charts',
            'includeVersion': custom_include_version,
        }
    conn.execute("INSERT INTO metadata (key, value) VALUES (?, ?)",
                 ('providers', json.dumps(providers)))

    conn.commit()
    conn.close()

    # Report results
    print(f"\nCatalog built: {db_path}")
    print(f"  Songs: {len(seen_titles)}")
    if custom_count > 0:
        print(f"  Custom charts: {custom_count}")
    if args.ranges_file:
        print(f"  With note ranges: {songs_with_ranges}")

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
