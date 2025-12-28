"""
SQLite database access layer for Jazz Picker catalog.
"""
import sqlite3
import json
from pathlib import Path
from contextlib import contextmanager

# Database file paths
LOCAL_DB_PATH = Path('catalog.db')
S3_DB_KEY = 'catalog.db'

# Global connection (initialized on first use)
_db_path = None


def init_db(db_path=None):
    """Initialize database path. Call once at startup."""
    global _db_path
    _db_path = db_path or LOCAL_DB_PATH

    if not Path(_db_path).exists():
        raise FileNotFoundError(f"Database not found: {_db_path}")

    # Verify we can connect
    with get_connection() as conn:
        cursor = conn.execute("SELECT COUNT(*) FROM songs")
        count = cursor.fetchone()[0]

    return count


@contextmanager
def get_connection():
    """Get a database connection. Use as context manager."""
    if _db_path is None:
        raise RuntimeError("Database not initialized. Call init_db() first.")

    conn = sqlite3.connect(_db_path)
    conn.row_factory = sqlite3.Row  # Enable column access by name
    try:
        yield conn
    finally:
        conn.close()


def get_metadata():
    """Get catalog metadata."""
    with get_connection() as conn:
        cursor = conn.execute("SELECT key, value FROM metadata")
        return {row['key']: row['value'] for row in cursor.fetchall()}


def get_total_songs():
    """Get total number of songs."""
    with get_connection() as conn:
        cursor = conn.execute("SELECT COUNT(*) FROM songs")
        return cursor.fetchone()[0]


def get_all_songs():
    """
    Get all songs sorted alphabetically.
    Returns lightweight list with title, default_key, and composer.
    """
    with get_connection() as conn:
        cursor = conn.execute(
            "SELECT title, default_key, composer, low_note_midi, high_note_midi FROM songs ORDER BY title"
        )
        return [
            {
                'title': row['title'],
                'default_key': row['default_key'],
                'composer': row['composer'],
                'low_note_midi': row['low_note_midi'],
                'high_note_midi': row['high_note_midi'],
            }
            for row in cursor.fetchall()
        ]


def search_songs(query='', limit=50, offset=0):
    """
    Search songs by title.
    Returns list of song dicts and total count.
    """
    with get_connection() as conn:
        params = []

        # Base query
        base_query = "SELECT id, title, default_key, composer FROM songs"

        # Build WHERE clause for search
        if query:
            base_query += " WHERE LOWER(title) LIKE ?"
            params.append(f"%{query.lower()}%")

        base_query += " ORDER BY title"

        # Add pagination
        base_query += " LIMIT ? OFFSET ?"
        params.extend([limit, offset])

        cursor = conn.execute(base_query, params)
        songs = []
        for row in cursor.fetchall():
            songs.append({
                'title': row['title'],
                'default_key': row['default_key'],
                'composer': row['composer'],
            })

        # Get total count (without pagination)
        count_query = "SELECT COUNT(*) FROM songs"
        if query:
            count_query += " WHERE LOWER(title) LIKE ?"
            count_params = [f"%{query.lower()}%"]
        else:
            count_params = []

        cursor = conn.execute(count_query, count_params)
        total = cursor.fetchone()[0]

        return songs, total


def get_song_by_title(title):
    """Get a song by title."""
    with get_connection() as conn:
        cursor = conn.execute(
            "SELECT id, title, default_key, core_files, low_note_midi, high_note_midi FROM songs WHERE title = ?",
            (title,)
        )
        row = cursor.fetchone()

        if not row:
            return None

        return {
            'id': row['id'],
            'title': row['title'],
            'default_key': row['default_key'],
            'core_files': json.loads(row['core_files']) if row['core_files'] else [],
            'low_note_midi': row['low_note_midi'],
            'high_note_midi': row['high_note_midi'],
        }


def get_song_default_key(title):
    """
    Get the default concert key for a song.
    Returns (key, clef) tuple, or ('c', 'treble') if not found.
    Clef is always 'treble' - bass clef is determined by user's instrument setting.
    """
    with get_connection() as conn:
        cursor = conn.execute(
            "SELECT default_key FROM songs WHERE title = ?",
            (title,)
        )
        row = cursor.fetchone()
        if row and row['default_key']:
            return row['default_key'], 'treble'

        return 'c', 'treble'


def get_core_files(title):
    """Get core files for a song."""
    with get_connection() as conn:
        cursor = conn.execute(
            "SELECT core_files FROM songs WHERE title = ?",
            (title,)
        )
        row = cursor.fetchone()
        if row and row['core_files']:
            return json.loads(row['core_files'])
        return []


def song_exists(title):
    """Check if a song exists in the catalog."""
    with get_connection() as conn:
        cursor = conn.execute(
            "SELECT 1 FROM songs WHERE title = ? LIMIT 1",
            (title,)
        )
        return cursor.fetchone() is not None


def get_song_note_range(title):
    """
    Get the MIDI note range for a song's melody.
    Returns (low_note_midi, high_note_midi) tuple, or (None, None) if not found.
    """
    with get_connection() as conn:
        cursor = conn.execute(
            "SELECT low_note_midi, high_note_midi FROM songs WHERE title = ?",
            (title,)
        )
        row = cursor.fetchone()
        if row:
            return row['low_note_midi'], row['high_note_midi']
        return None, None


def get_song_source(title):
    """
    Get the source of a song ('standard' or 'custom').
    Returns 'standard' if not found.
    """
    with get_connection() as conn:
        cursor = conn.execute(
            "SELECT source FROM songs WHERE title = ?",
            (title,)
        )
        row = cursor.fetchone()
        if row and row['source']:
            return row['source']
        return 'standard'


def get_providers():
    """
    Get providers metadata including includeVersion for cache invalidation.
    Returns dict of provider objects, e.g.:
    {
        'standard': {'id': 'standard', 'name': 'Eric Royer', 'includeVersion': 'abc123'},
        'custom': {'id': 'custom', 'name': 'Custom Charts', 'includeVersion': 'abc123'}
    }
    """
    with get_connection() as conn:
        cursor = conn.execute(
            "SELECT value FROM metadata WHERE key = 'providers'"
        )
        row = cursor.fetchone()
        if row and row['value']:
            return json.loads(row['value'])
        return {}


def get_include_version(source='standard'):
    """
    Get the includeVersion for a source/provider.
    Returns None if not found.
    """
    providers = get_providers()
    provider = providers.get(source)
    if provider:
        return provider.get('includeVersion')
    return None


def get_song_core_modified(title):
    """
    Get the core_modified timestamp for a song.
    Returns ISO timestamp string or None if not found.
    """
    with get_connection() as conn:
        cursor = conn.execute(
            "SELECT core_modified FROM songs WHERE title = ?",
            (title,)
        )
        row = cursor.fetchone()
        if row and row['core_modified']:
            return row['core_modified']
        return None
