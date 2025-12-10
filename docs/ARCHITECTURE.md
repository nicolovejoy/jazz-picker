# Architecture

## Data Model

```
users/{uid}           (Firestore)
  - instrument, displayName, createdAt, updatedAt

setlists/{id}         (Firestore)
  - name, ownerId, items[], createdAt, updatedAt
  - items: [{ id, songTitle, concertKey, position, octaveOffset, notes }]

songs                 (SQLite on backend)
  - id, title, default_key, core_files
  - low_note_midi, high_note_midi (pending catalog rebuild)
```

## Auth Flow

**Web:** Open app → Firebase checks auth → Sign in (if needed) → Load profile → Show app

**iOS:** Same pattern using Apple Sign-In → Start Firestore listeners for profile and setlists

## PDF Generation

1. Client requests PDF with {title, key, transposition, clef}
2. Backend checks S3 cache
3. Cache hit → return URL; Cache miss → run LilyPond → upload to S3 → return URL

## Setlist Sync

Both iOS and web use Firestore real-time listeners:
- Changes sync instantly across all devices
- Optimistic UI updates with rollback on error
- `lastOpenedAt` is local-only per device (not synced)

## Firestore Security

```
/users/{uid}: read/write if auth.uid == uid
/setlists/{id}: read/write if authenticated (shared access for band)
```
