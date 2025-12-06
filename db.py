"""
SQLite database access layer for Jazz Picker catalog and setlists.
"""
import sqlite3
import json
import uuid
from datetime import datetime
from pathlib import Path
from contextlib import contextmanager

# Database file paths
LOCAL_DB_PATH = Path('catalog.db')
SETLISTS_DB_PATH = Path('setlists.db')
S3_DB_KEY = 'catalog.db'

# Global connection (initialized on first use)
_db_path = None
_setlists_db_path = None


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
    Returns lightweight list with just title and default_key.
    """
    with get_connection() as conn:
        cursor = conn.execute(
            "SELECT title, default_key FROM songs ORDER BY title"
        )
        return [
            {'title': row['title'], 'default_key': row['default_key']}
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
        base_query = "SELECT id, title, default_key FROM songs"

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


# =============================================================================
# Setlists Database
# =============================================================================

def init_setlists_db(db_path=None):
    """Initialize setlists database, creating tables if needed."""
    global _setlists_db_path
    _setlists_db_path = db_path or SETLISTS_DB_PATH

    conn = sqlite3.connect(_setlists_db_path)
    conn.row_factory = sqlite3.Row

    # Create tables
    conn.executescript('''
        CREATE TABLE IF NOT EXISTS setlists (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            created_by_device TEXT,
            deleted_at TEXT
        );

        CREATE TABLE IF NOT EXISTS setlist_items (
            id TEXT PRIMARY KEY,
            setlist_id TEXT NOT NULL REFERENCES setlists(id) ON DELETE CASCADE,
            song_title TEXT NOT NULL,
            concert_key TEXT NOT NULL,
            position INTEGER NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_setlist_items_setlist_id
            ON setlist_items(setlist_id);
    ''')
    conn.commit()
    conn.close()

    return True


@contextmanager
def get_setlists_connection():
    """Get a setlists database connection. Use as context manager."""
    if _setlists_db_path is None:
        raise RuntimeError("Setlists database not initialized. Call init_setlists_db() first.")

    conn = sqlite3.connect(_setlists_db_path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    try:
        yield conn
    finally:
        conn.close()


def get_all_setlists():
    """Get all non-deleted setlists with their items."""
    with get_setlists_connection() as conn:
        cursor = conn.execute('''
            SELECT id, name, created_at, updated_at, created_by_device
            FROM setlists
            WHERE deleted_at IS NULL
            ORDER BY updated_at DESC
        ''')
        setlists = []
        for row in cursor.fetchall():
            setlist = {
                'id': row['id'],
                'name': row['name'],
                'created_at': row['created_at'],
                'updated_at': row['updated_at'],
                'created_by_device': row['created_by_device'],
                'items': []
            }
            # Get items for this setlist
            items_cursor = conn.execute('''
                SELECT id, song_title, concert_key, position, is_set_break
                FROM setlist_items
                WHERE setlist_id = ?
                ORDER BY position
            ''', (row['id'],))
            for item_row in items_cursor.fetchall():
                setlist['items'].append({
                    'id': item_row['id'],
                    'song_title': item_row['song_title'],
                    'concert_key': item_row['concert_key'],
                    'position': item_row['position'],
                    'is_set_break': bool(item_row['is_set_break'])
                })
            setlists.append(setlist)
        return setlists


def get_setlist(setlist_id):
    """Get a single setlist by ID, or None if not found/deleted."""
    with get_setlists_connection() as conn:
        cursor = conn.execute('''
            SELECT id, name, created_at, updated_at, created_by_device
            FROM setlists
            WHERE id = ? AND deleted_at IS NULL
        ''', (setlist_id,))
        row = cursor.fetchone()
        if not row:
            return None

        setlist = {
            'id': row['id'],
            'name': row['name'],
            'created_at': row['created_at'],
            'updated_at': row['updated_at'],
            'created_by_device': row['created_by_device'],
            'items': []
        }

        # Get items
        items_cursor = conn.execute('''
            SELECT id, song_title, concert_key, position, is_set_break
            FROM setlist_items
            WHERE setlist_id = ?
            ORDER BY position
        ''', (setlist_id,))
        for item_row in items_cursor.fetchall():
            setlist['items'].append({
                'id': item_row['id'],
                'song_title': item_row['song_title'],
                'concert_key': item_row['concert_key'],
                'position': item_row['position'],
                'is_set_break': bool(item_row['is_set_break'])
            })

        return setlist


def create_setlist(name, items=None, device_id=None):
    """
    Create a new setlist.

    Args:
        name: Setlist name
        items: List of dicts with song_title, concert_key
        device_id: Optional device ID for attribution

    Returns:
        The created setlist dict
    """
    setlist_id = str(uuid.uuid4())
    now = datetime.utcnow().isoformat() + 'Z'

    with get_setlists_connection() as conn:
        conn.execute('''
            INSERT INTO setlists (id, name, created_at, updated_at, created_by_device)
            VALUES (?, ?, ?, ?, ?)
        ''', (setlist_id, name, now, now, device_id))

        # Add items if provided
        if items:
            for i, item in enumerate(items):
                item_id = str(uuid.uuid4())
                is_set_break = 1 if item.get('is_set_break', False) else 0
                conn.execute('''
                    INSERT INTO setlist_items (id, setlist_id, song_title, concert_key, position, is_set_break)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (item_id, setlist_id, item['song_title'], item['concert_key'], i, is_set_break))

        conn.commit()

    return get_setlist(setlist_id)


def update_setlist(setlist_id, name=None, items=None):
    """
    Update a setlist. Replaces items entirely if provided.

    Args:
        setlist_id: ID of setlist to update
        name: New name (optional)
        items: New items list (optional, replaces all existing items)

    Returns:
        Updated setlist dict, or None if not found
    """
    with get_setlists_connection() as conn:
        # Check if exists and not deleted
        cursor = conn.execute(
            'SELECT id FROM setlists WHERE id = ? AND deleted_at IS NULL',
            (setlist_id,)
        )
        if not cursor.fetchone():
            return None

        now = datetime.utcnow().isoformat() + 'Z'

        # Update name if provided
        if name is not None:
            conn.execute(
                'UPDATE setlists SET name = ?, updated_at = ? WHERE id = ?',
                (name, now, setlist_id)
            )
        else:
            conn.execute(
                'UPDATE setlists SET updated_at = ? WHERE id = ?',
                (now, setlist_id)
            )

        # Replace items if provided
        if items is not None:
            conn.execute('DELETE FROM setlist_items WHERE setlist_id = ?', (setlist_id,))
            for i, item in enumerate(items):
                item_id = item.get('id') or str(uuid.uuid4())
                is_set_break = 1 if item.get('is_set_break', False) else 0
                conn.execute('''
                    INSERT INTO setlist_items (id, setlist_id, song_title, concert_key, position, is_set_break)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (item_id, setlist_id, item['song_title'], item['concert_key'], i, is_set_break))

        conn.commit()

    return get_setlist(setlist_id)


def delete_setlist(setlist_id):
    """
    Soft-delete a setlist.

    Returns:
        True if deleted, False if not found
    """
    with get_setlists_connection() as conn:
        cursor = conn.execute(
            'SELECT id FROM setlists WHERE id = ? AND deleted_at IS NULL',
            (setlist_id,)
        )
        if not cursor.fetchone():
            return False

        now = datetime.utcnow().isoformat() + 'Z'
        conn.execute(
            'UPDATE setlists SET deleted_at = ? WHERE id = ?',
            (now, setlist_id)
        )
        conn.commit()

    return True
