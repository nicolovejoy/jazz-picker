# Architecture

## Entity Relationship Diagram

```
+-------------------+       +-------------------+       +-------------------+
|      users        |       |     setlists      |       |   setlist_items   |
|   (Firestore)     |       |   (Firestore)     |       |  (embedded array) |
+-------------------+       +-------------------+       +-------------------+
| uid (PK)          |       | id (PK)           |       | id                |
| instrument        |       | name              |       | songTitle         |
| displayName       |       | ownerId --------->|       | concertKey        |
| createdAt         |       | items[] ----------|------>| position          |
| updatedAt         |       | createdAt         |       | octaveOffset      |
+-------------------+       | updatedAt         |       | notes             |
                            +-------------------+       +-------------------+

+-------------------+
|      songs        |
|    (SQLite)       |
+-------------------+
| id (PK)           |
| title             |
| default_key       |
| core_files        |
| low_note_midi     |      (pending catalog rebuild)
| high_note_midi    |      (pending catalog rebuild)
| created_at        |
+-------------------+
```

### Notes

- **users**: One document per authenticated user, keyed by Firebase UID
- **setlists**: Shared across all users (intentional for 2-user band setup)
- **setlist_items**: Embedded in setlist document as array, not a subcollection
- **songs**: SQLite database on Flask backend, loaded from catalog.db

---

## Authentication Flow (Web)

### Current State (Phases 1-4 Complete)

```
User                    Web App                 Firebase Auth           Firestore
 |                         |                         |                      |
 |  1. Open app            |                         |                      |
 |------------------------>|                         |                      |
 |                         |                         |                      |
 |                         | 2. onAuthStateChanged() |                      |
 |                         |<------------------------|                      |
 |                         |   user = null           |                      |
 |                         |                         |                      |
 | 3. Show SignIn page     |                         |                      |
 |<------------------------|                         |                      |
 |                         |                         |                      |
 | 4. Click "Apple/Google" |                         |                      |
 |------------------------>|                         |                      |
 |                         | 5. signInWithPopup()    |                      |
 |                         |------------------------>|                      |
 |                         |                         |                      |
 |                         | 6. Return user          |                      |
 |                         |<------------------------|                      |
 |                         |                         |                      |
 |                         | 7. subscribeToProfile(uid)                     |
 |                         |------------------------------------------------>|
 |                         |                         |                      |
 |                         | 8. profile = null (new user)                   |
 |                         |<------------------------------------------------|
 |                         |                         |                      |
 | 9. Show OnboardingModal |                         |                      |
 |<------------------------|                         |                      |
 |                         |                         |                      |
 | 10. Select instrument,  |                         |                      |
 |     enter name          |                         |                      |
 |------------------------>|                         |                      |
 |                         | 11. createProfile()                            |
 |                         |------------------------------------------------>|
 |                         |                         |                      |
 |                         | 12. Profile created, real-time update          |
 |                         |<------------------------------------------------|
 |                         |                         |                      |
 | 13. Show main app       |                         |                      |
 |<------------------------|                         |                      |
```

### Returning User Flow

```
User                    Web App                 Firebase Auth           Firestore
 |                         |                         |                      |
 |  1. Open app            |                         |                      |
 |------------------------>|                         |                      |
 |                         |                         |                      |
 |                         | 2. onAuthStateChanged() |                      |
 |                         |<------------------------|                      |
 |                         |   user = {uid, email...}|                      |
 |                         |                         |                      |
 |                         | 3. subscribeToProfile(uid)                     |
 |                         |------------------------------------------------>|
 |                         |                         |                      |
 |                         | 4. profile = {instrument, displayName...}      |
 |                         |<------------------------------------------------|
 |                         |                         |                      |
 | 5. Show main app        |                         |                      |
 |<------------------------|                         |                      |
```

---

## Setlist Flow (Web)

### Current State (Phase 4 Complete)

```
User                    Web App                 Firestore
 |                         |                      |
 | 1. Navigate to Setlists |                      |
 |------------------------>|                      |
 |                         |                      |
 |                         | 2. subscribeToSetlists()
 |                         |--------------------->|
 |                         |                      |
 |                         | 3. Real-time snapshot|
 |                         |<---------------------|
 |                         |                      |
 | 4. Show setlist list    |                      |
 |<------------------------|                      |
 |                         |                      |
 | 5. Create new setlist   |                      |
 |------------------------>|                      |
 |                         | 6. createSetlist()   |
 |                         |--------------------->|
 |                         |                      |
 |                         | 7. Real-time update  |
 |                         |<---------------------|
 |                         |                      |
 | 8. UI updates instantly |                      |
 |<------------------------|                      |
 |                         |                      |
 | 9. Add song to setlist  |                      |
 |------------------------>|                      |
 |                         | 10. addItem()        |
 |                         |--------------------->|
 |                         |                      |
 |                         | 11. Real-time update |
 |                         |<---------------------|
 |                         |                      |
 | 12. UI updates instantly|                      |
 |<------------------------|                      |
```

### Cross-Device Sync (2 users in same band)

```
User A (iPad)           Firestore               User B (Phone)
 |                         |                      |
 | 1. Create setlist       |                      |
 |------------------------>|                      |
 |                         |                      |
 |                         | 2. Broadcast update  |
 |                         |--------------------->|
 |                         |                      |
 |                         | 3. Setlist appears   |
 |                         |<---------------------|
 |                         |                      |
 | 4. Add "All The Things" |                      |
 |------------------------>|                      |
 |                         |                      |
 |                         | 5. Broadcast update  |
 |                         |--------------------->|
 |                         |                      |
 |                         | 6. Song appears      |
 |                         |<---------------------|
```

---

## PDF Generation Flow

```
User                    Web App                 Flask Backend           S3 / LilyPond
 |                         |                         |                      |
 | 1. Tap song             |                         |                      |
 |------------------------>|                         |                      |
 |                         | 2. POST /api/v2/generate                       |
 |                         |    {title, key, transposition, clef}           |
 |                         |------------------------>|                      |
 |                         |                         |                      |
 |                         |                         | 3. Check S3 cache    |
 |                         |                         |--------------------->|
 |                         |                         |                      |
 |                         |                         | 4a. Cache HIT        |
 |                         |                         |<---------------------|
 |                         |                         |                      |
 |                         | 5a. Return S3 URL       |                      |
 |                         |<------------------------|                      |
 |                         |                         |                      |
 |                         |                         | 4b. Cache MISS       |
 |                         |                         |<---------------------|
 |                         |                         |                      |
 |                         |                         | 5b. Run LilyPond     |
 |                         |                         |--------------------->|
 |                         |                         |                      |
 |                         |                         | 6b. Upload to S3     |
 |                         |                         |--------------------->|
 |                         |                         |                      |
 |                         | 7b. Return S3 URL       |                      |
 |                         |<------------------------|                      |
 |                         |                         |                      |
 | 8. Display PDF          |                         |                      |
 |<------------------------|                         |                      |
```

---

## iOS Authentication Flow (Phase 5 - Planned)

```
User                    iOS App                 Firebase Auth           Firestore
 |                         |                         |                      |
 | 1. Launch app           |                         |                      |
 |------------------------>|                         |                      |
 |                         |                         |                      |
 |                         | 2. Check auth state     |                      |
 |                         |------------------------>|                      |
 |                         |                         |                      |
 |                         | 3. Not signed in        |                      |
 |                         |<------------------------|                      |
 |                         |                         |                      |
 | 4. Show SignIn screen   |                         |                      |
 |    (Apple Sign-In only) |                         |                      |
 |<------------------------|                         |                      |
 |                         |                         |                      |
 | 5. Tap "Sign in with    |                         |                      |
 |    Apple"               |                         |                      |
 |------------------------>|                         |                      |
 |                         | 6. ASAuthorizationController                   |
 |                         |    (native Apple UI)    |                      |
 |                         |------------------------>|                      |
 |                         |                         |                      |
 |                         | 7. Apple credential     |                      |
 |                         |<------------------------|                      |
 |                         |                         |                      |
 |                         | 8. signIn(with: credential)                    |
 |                         |------------------------>|                      |
 |                         |                         |                      |
 |                         | 9. Firebase user        |                      |
 |                         |<------------------------|                      |
 |                         |                         |                      |
 |                         | 10. Fetch/create profile                       |
 |                         |------------------------------------------------>|
 |                         |                         |                      |
 | 11. Show main app       |                         |                      |
 |    or onboarding        |                         |                      |
 |<------------------------|                         |                      |
```

---

## iOS Setlist Flow (Phase 6 - Planned)

Same as Web setlist flow, using Firebase iOS SDK instead of web SDK. Will replace current Flask-based setlist sync.

---

## Security Rules Summary

```
Firestore Rules:
- /users/{uid}: read/write only if request.auth.uid == uid
- /setlists/{id}: read/write if request.auth != null (shared access)

Flask Backend:
- Token verification disabled (no GCP credentials on Fly.io)
- All API requests allowed without authentication
- To enable: add GOOGLE_APPLICATION_CREDENTIALS_JSON to Fly secrets
```
