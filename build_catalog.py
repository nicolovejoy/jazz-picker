#!/usr/bin/env python3
"""
Build a catalog of all available lead sheets from the Wrappers directory.

This script scans all .ly files in the Wrappers directory and extracts:
- Song title
- Default concert key (from Standard Key variation)
- Core file reference

Output: catalog.db (SQLite database)
"""

import os
import re
import json
import sqlite3
from pathlib import Path
from collections import defaultdict
from datetime import datetime

# Regex patterns for parsing wrapper files
WHAT_KEY_PATTERN = re.compile(r'whatKey\s*=\s*([a-z,\'"]+)')
INCLUDE_CORE_PATTERN = re.compile(r'\\include\s+"\.\./Core/([^"]+)"')

# Filename pattern: {Title} - Ly - {Key} {Variation}.ly
FILENAME_PATTERN = re.compile(r'^(.+?) - Ly - (.+?)\.ly$')


def parse_wrapper_file(filepath):
    """Parse a single wrapper file and extract metadata."""
    filename = os.path.basename(filepath)

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Parse filename for title and variation info
    filename_match = FILENAME_PATTERN.match(filename)
    if not filename_match:
        return None

    file_title, key_and_variation = filename_match.groups()

    # Extract key and core file from content
    key_match = WHAT_KEY_PATTERN.search(content)
    core_match = INCLUDE_CORE_PATTERN.search(content)

    metadata = {
        'title': file_title,
        'key_and_variation': key_and_variation,
    }

    if key_match:
        # Strip octave markers (commas and apostrophes)
        metadata['key'] = key_match.group(1).strip().rstrip(",'")

    if core_match:
        metadata['core_file'] = core_match.group(1)

    # Determine if this is a Standard Key variation (used for default key)
    is_standard = 'Standard' in key_and_variation and 'for Bb' not in key_and_variation and 'for Eb' not in key_and_variation and 'Bass for' not in key_and_variation
    metadata['is_standard_key'] = is_standard

    return metadata


def init_database(db_path='catalog.db'):
    """Initialize SQLite database with schema."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Drop existing tables (fresh start each time)
    cursor.execute('DROP TABLE IF EXISTS variations')  # Remove legacy table
    cursor.execute('DROP TABLE IF EXISTS songs')
    cursor.execute('DROP TABLE IF EXISTS metadata')

    # Songs table - simplified, just title + default key + core files
    cursor.execute('''
        CREATE TABLE songs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT UNIQUE NOT NULL,
            default_key TEXT DEFAULT 'c',
            core_files TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    cursor.execute('CREATE INDEX idx_songs_title ON songs(title)')

    # Metadata table
    cursor.execute('''
        CREATE TABLE metadata (
            key TEXT PRIMARY KEY,
            value TEXT
        )
    ''')

    conn.commit()
    return conn


def build_catalog(wrappers_dir='lilypond-data/Wrappers'):
    """Build a complete catalog of all wrapper files."""
    wrappers_path = Path(wrappers_dir)

    if not wrappers_path.exists():
        print(f"Error: {wrappers_dir} directory not found")
        return None

    # Collect song data
    songs = defaultdict(lambda: {
        'title': '',
        'default_key': 'c',
        'core_files': set(),
    })

    # Scan all .ly files in Wrappers
    wrapper_files = list(wrappers_path.glob('*.ly'))
    print(f"Scanning {len(wrapper_files)} wrapper files...")

    for filepath in wrapper_files:
        metadata = parse_wrapper_file(filepath)
        if metadata:
            song_title = metadata['title']
            songs[song_title]['title'] = song_title

            if 'core_file' in metadata:
                songs[song_title]['core_files'].add(metadata['core_file'])

            # Use Standard Key variation for default key
            if metadata.get('is_standard_key') and 'key' in metadata:
                songs[song_title]['default_key'] = metadata['key']

    return {
        'songs': songs,
        'total_files': len(wrapper_files),
        'total_songs': len(songs),
    }


def save_to_database(catalog, db_path='catalog.db'):
    """Save catalog to SQLite database."""
    conn = init_database(db_path)
    cursor = conn.cursor()

    # Save metadata
    cursor.execute('INSERT INTO metadata (key, value) VALUES (?, ?)',
                   ('total_songs', str(catalog['total_songs'])))
    cursor.execute('INSERT INTO metadata (key, value) VALUES (?, ?)',
                   ('total_files', str(catalog['total_files'])))
    cursor.execute('INSERT INTO metadata (key, value) VALUES (?, ?)',
                   ('generated', datetime.now().isoformat()))

    # Save songs
    for song_title, song_data in catalog['songs'].items():
        cursor.execute(
            'INSERT INTO songs (title, default_key, core_files) VALUES (?, ?, ?)',
            (
                song_title,
                song_data['default_key'],
                json.dumps(sorted(list(song_data['core_files'])))
            )
        )

    conn.commit()
    conn.close()
    print(f"Database saved to {db_path}")


def print_summary(catalog):
    """Print a summary of the catalog."""
    print("\n" + "="*60)
    print("CATALOG SUMMARY")
    print("="*60)
    print(f"Total wrapper files: {catalog['total_files']}")
    print(f"Total unique songs: {catalog['total_songs']}")
    print("\nSample songs:")

    for i, (title, data) in enumerate(list(catalog['songs'].items())[:10]):
        print(f"  {i+1}. {title} (key: {data['default_key']})")


if __name__ == '__main__':
    print("Building lead sheet catalog...")
    catalog = build_catalog()

    if catalog:
        save_to_database(catalog)
        print_summary(catalog)
        print("\n✓ Catalog built successfully!")
        print("  → catalog.db (SQLite database)")
    else:
        print("\n✗ Failed to build catalog")
