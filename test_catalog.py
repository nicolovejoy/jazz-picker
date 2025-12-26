#!/usr/bin/env python3
"""
Tests for catalog build process.

Run with: python3 test_catalog.py
Or with pytest: pytest test_catalog.py -v
"""

import sqlite3
import subprocess
import tempfile
import os
from pathlib import Path


def build_catalog(output_path: str, custom_dir: str = None, skip_ranges: bool = True) -> str:
    """Build catalog and return path to database."""
    cmd = ["python3", "build_catalog.py", "--output", output_path]

    if skip_ranges:
        cmd.append("--skip-ranges")

    if custom_dir:
        cmd.extend(["--custom-dir", custom_dir])

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"Build failed: {result.stderr}")

    return output_path


def test_standard_songs_included():
    """Catalog should include 700+ standard songs from lilypond-data."""
    with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
        db_path = f.name

    try:
        build_catalog(db_path)

        conn = sqlite3.connect(db_path)
        count = conn.execute("SELECT COUNT(*) FROM songs WHERE source = 'standard'").fetchone()[0]
        conn.close()

        assert count > 700, f"Expected 700+ standard songs, got {count}"
        print(f"OK: {count} standard songs found")
    finally:
        os.unlink(db_path)


def test_custom_songs_included():
    """Catalog should include custom songs when --custom-dir is provided."""
    with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
        db_path = f.name

    try:
        build_catalog(db_path, custom_dir="custom-charts")

        conn = sqlite3.connect(db_path)
        count = conn.execute("SELECT COUNT(*) FROM songs WHERE source = 'custom'").fetchone()[0]
        conn.close()

        assert count >= 1, f"Expected at least 1 custom song, got {count}"
        print(f"OK: {count} custom songs found")
    finally:
        os.unlink(db_path)


def test_specific_custom_song_exists():
    """James' song should be in the catalog with source='custom'."""
    with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
        db_path = f.name

    try:
        build_catalog(db_path, custom_dir="custom-charts")

        conn = sqlite3.connect(db_path)
        row = conn.execute(
            "SELECT title, source FROM songs WHERE title = 'My Window Faces the South'"
        ).fetchone()
        conn.close()

        assert row is not None, "James' song 'My Window Faces the South' not found"
        assert row[1] == "custom", f"Expected source='custom', got '{row[1]}'"
        print(f"OK: Found '{row[0]}' with source='{row[1]}'")
    finally:
        os.unlink(db_path)


def test_no_custom_songs_without_flag():
    """Without --custom-dir, no custom songs should be included."""
    with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
        db_path = f.name

    try:
        build_catalog(db_path)  # No custom_dir

        conn = sqlite3.connect(db_path)
        count = conn.execute("SELECT COUNT(*) FROM songs WHERE source = 'custom'").fetchone()[0]
        conn.close()

        assert count == 0, f"Expected 0 custom songs without --custom-dir, got {count}"
        print("OK: No custom songs when --custom-dir not provided")
    finally:
        os.unlink(db_path)


if __name__ == "__main__":
    # Run tests directly
    os.chdir(Path(__file__).parent)

    tests = [
        test_standard_songs_included,
        test_custom_songs_included,
        test_specific_custom_song_exists,
        test_no_custom_songs_without_flag,
    ]

    passed = 0
    failed = 0

    for test in tests:
        print(f"\n--- {test.__name__} ---")
        try:
            test()
            passed += 1
        except Exception as e:
            print(f"FAILED: {e}")
            failed += 1

    print(f"\n{'='*40}")
    print(f"Results: {passed} passed, {failed} failed")

    if failed > 0:
        exit(1)
