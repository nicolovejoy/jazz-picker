#!/usr/bin/env python3
"""
Import Eric's TeX book files as Firestore setlists.

Usage:
    python tools/import_book_setlist.py "Alto Voice Book"
    python tools/import_book_setlist.py --list  # Show available books
"""

import argparse
import os
import re
import sys
from pathlib import Path

# Add parent dir for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

TEX_DIR = Path(__file__).parent.parent / "lilypond-data" / "TeX"


def list_books():
    """List available book files."""
    books = sorted(TEX_DIR.glob("*Book.tex"))
    print("Available books:")
    for b in books:
        print(f"  - {b.stem}")


def parse_key(key_str: str) -> str:
    """
    Convert display key to API format.
    'Db' -> 'df', 'F#m' -> 'fsm', 'Bb' -> 'bf'
    """
    key = key_str.strip()

    # Handle minor
    is_minor = key.endswith("m")
    if is_minor:
        key = key[:-1]

    # Handle sharps/flats
    if len(key) == 2:
        note = key[0].lower()
        accidental = key[1]
        if accidental == "#":
            key = note + "s"
        elif accidental == "b":
            key = note + "f"
        else:
            key = key.lower()
    else:
        key = key.lower()

    if is_minor:
        key += "m"

    return key


def parse_tex_book(book_path: Path) -> list[dict]:
    r"""
    Parse a TeX book file and extract songs.

    Only includes main entries (\song, \msong, \dmsong, \dsong).
    Skips alternate keys (\xsong, \dxsong).
    """
    content = book_path.read_text()

    # Match \song{Title - Key}, \msong{...}, \dmsong{...}, \dsong{...}
    # Skip \xsong and \dxsong (alternate keys)
    pattern = r"\\(?:d?m?song)\{([^}]+)\}"

    songs = []
    seen_titles = set()

    for match in re.finditer(pattern, content):
        title_key = match.group(1)

        # Parse "Title - Key" format
        # Handle special cases like "A Child Is Born - Bb" or "All the Things You Are - Ab"
        parts = title_key.rsplit(" - ", 1)
        if len(parts) != 2:
            print(f"  Warning: Could not parse '{title_key}'")
            continue

        title, key_display = parts
        title = title.strip()

        # Skip duplicates (we only want one entry per song)
        if title in seen_titles:
            continue
        seen_titles.add(title)

        # Handle keys with extra info like "D to E (Capo 2)" -> just take "D"
        key_display = key_display.split(" to ")[0].split(" (")[0].strip()

        concert_key = parse_key(key_display)

        songs.append({
            "title": title,
            "concertKey": concert_key,
        })

    return songs


def create_setlist(db, book_name: str, songs: list[dict], owner_id: str, group_id: str, dry_run: bool = False):
    """Create or update a Firestore setlist from parsed songs."""

    setlist_name = book_name.replace(" Book", "")  # "Alto Voice Book" -> "Alto Voice"

    items = []
    for i, song in enumerate(songs):
        items.append({
            "id": f"book-{i}",
            "songTitle": song["title"],
            "concertKey": song["concertKey"],
            "position": i,
            "isSetBreak": False,
        })

    setlist_data = {
        "name": setlist_name,
        "ownerId": owner_id,
        "groupId": group_id,
        "items": items,
    }

    if dry_run:
        print(f"\nDry run - would create setlist '{setlist_name}' with {len(items)} songs")
        print(f"First 5 songs:")
        for item in items[:5]:
            print(f"  - {item['songTitle']} ({item['concertKey']})")
        return None

    # Check if setlist already exists
    setlists_ref = db.collection("setlists")
    existing = setlists_ref.where("name", "==", setlist_name).where("ownerId", "==", owner_id).limit(1).get()

    if existing:
        doc = existing[0]
        doc.reference.update(setlist_data)
        print(f"Updated setlist '{setlist_name}' ({doc.id}) with {len(items)} songs")
        return doc.id
    else:
        doc_ref = setlists_ref.add(setlist_data)
        print(f"Created setlist '{setlist_name}' ({doc_ref[1].id}) with {len(items)} songs")
        return doc_ref[1].id


def main():
    parser = argparse.ArgumentParser(description="Import TeX books as Firestore setlists")
    parser.add_argument("book", nargs="?", help="Book name (e.g., 'Alto Voice Book')")
    parser.add_argument("--list", action="store_true", help="List available books")
    parser.add_argument("--dry-run", action="store_true", help="Parse only, don't write to Firestore")
    parser.add_argument("--owner-id", required=False, help="Firebase user ID to own the setlist")
    parser.add_argument("--group-id", required=False, help="Band/group ID for the setlist")
    args = parser.parse_args()

    if args.list:
        list_books()
        return

    if not args.book:
        parser.print_help()
        return

    # Find book file
    book_name = args.book
    if not book_name.endswith(".tex"):
        book_name = book_name + ".tex"

    book_path = TEX_DIR / book_name
    if not book_path.exists():
        # Try with "Book" suffix
        book_path = TEX_DIR / (args.book + " Book.tex")

    if not book_path.exists():
        print(f"Error: Book not found: {args.book}")
        print(f"Looked in: {TEX_DIR}")
        list_books()
        return

    print(f"Parsing: {book_path.name}")
    songs = parse_tex_book(book_path)
    print(f"Found {len(songs)} songs")

    if args.dry_run:
        create_setlist(None, book_path.stem, songs, owner_id="", group_id="", dry_run=True)
        return

    # Validate required args for Firestore write
    if not args.owner_id or not args.group_id:
        print("Error: --owner-id and --group-id are required (unless using --dry-run)")
        return

    # Import Firebase only when needed
    import firebase_admin
    from firebase_admin import credentials, firestore

    # Initialize Firebase
    if not firebase_admin._apps:
        # Use default credentials (GOOGLE_APPLICATION_CREDENTIALS env var)
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred, {
            'projectId': 'jazz-picker-84158'
        })

    db = firestore.client()
    create_setlist(db, book_path.stem, songs, owner_id=args.owner_id, group_id=args.group_id)


if __name__ == "__main__":
    main()
