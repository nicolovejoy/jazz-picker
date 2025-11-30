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


def get_total_variations():
    """Get total number of variations."""
    with get_connection() as conn:
        cursor = conn.execute("SELECT COUNT(*) FROM variations")
        return cursor.fetchone()[0]


def search_songs(query='', instrument_filter='All', limit=50, offset=0):
    """
    Search songs with optional filtering.
    Returns list of song dicts with variation counts.
    """
    with get_connection() as conn:
        # Build the query based on filters
        params = []

        # Base query - join songs with variations to filter and count
        base_query = """
            SELECT
                s.id,
                s.title,
                s.core_files,
                COUNT(v.id) as variation_count
            FROM songs s
            LEFT JOIN variations v ON s.id = v.song_id
        """

        # Build WHERE clause
        where_clauses = []

        if query:
            where_clauses.append("LOWER(s.title) LIKE ?")
            params.append(f"%{query.lower()}%")

        if instrument_filter != 'All':
            if instrument_filter == 'C':
                where_clauses.append(
                    "(v.variation_type LIKE '%Standard%' OR v.variation_type LIKE '%Alto%' OR v.variation_type LIKE '%Baritone%')"
                )
            elif instrument_filter == 'Bb':
                where_clauses.append("v.variation_type LIKE '%Bb Instrument%'")
            elif instrument_filter == 'Eb':
                where_clauses.append("v.variation_type LIKE '%Eb Instrument%'")
            elif instrument_filter == 'Bass':
                where_clauses.append("v.variation_type = 'Bass'")

        if where_clauses:
            base_query += " WHERE " + " AND ".join(where_clauses)

        base_query += " GROUP BY s.id, s.title ORDER BY s.title"

        # Add pagination
        base_query += " LIMIT ? OFFSET ?"
        params.extend([limit, offset])

        cursor = conn.execute(base_query, params)
        songs = []
        for row in cursor.fetchall():
            songs.append({
                'title': row['title'],
                'variation_count': row['variation_count'],
                'available_instruments': [],  # We'll compute this if needed
            })

        # Get total count (without pagination)
        count_query = """
            SELECT COUNT(DISTINCT s.id)
            FROM songs s
            LEFT JOIN variations v ON s.id = v.song_id
        """
        if where_clauses:
            count_query += " WHERE " + " AND ".join(where_clauses)

        # Remove limit/offset params for count query
        count_params = params[:-2] if params else []
        cursor = conn.execute(count_query, count_params)
        total = cursor.fetchone()[0]

        return songs, total


def get_song_by_title(title):
    """Get a song by title, including its variations."""
    with get_connection() as conn:
        # Get song
        cursor = conn.execute(
            "SELECT id, title, core_files FROM songs WHERE title = ?",
            (title,)
        )
        row = cursor.fetchone()

        if not row:
            return None

        song = {
            'id': row['id'],
            'title': row['title'],
            'core_files': json.loads(row['core_files']) if row['core_files'] else [],
        }

        # Get variations
        cursor = conn.execute("""
            SELECT
                id, filename, display_name, key, instrument,
                variation_type, voice_range, pdf_path
            FROM variations
            WHERE song_id = ?
        """, (row['id'],))

        song['variations'] = [dict(r) for r in cursor.fetchall()]

        return song


def get_song_default_key(title):
    """
    Get the default key and clef for a song.
    Returns (key, clef) tuple, or ('c', 'treble') if not found.
    """
    with get_connection() as conn:
        cursor = conn.execute("""
            SELECT v.key, v.variation_type
            FROM songs s
            JOIN variations v ON s.id = v.song_id
            WHERE s.title = ? AND v.variation_type = 'Standard Key'
            LIMIT 1
        """, (title,))

        row = cursor.fetchone()
        if row:
            key = row['key'].rstrip(",'") if row['key'] else 'c'
            # Standard Key is always treble
            return key, 'treble'

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
