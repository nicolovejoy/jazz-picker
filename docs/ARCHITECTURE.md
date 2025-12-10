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

**iOS (Phase 5):** Same pattern using Apple Sign-In only

## PDF Generation

1. Client requests PDF with {title, key, transposition, clef}
2. Backend checks S3 cache
3. Cache hit → return URL; Cache miss → run LilyPond → upload to S3 → return URL

## Firestore Security

```
/users/{uid}: read/write if auth.uid == uid
/setlists/{id}: read/write if authenticated (shared access for band)
```
