# Phase 3 & 4: Offline Storage + Shared Setlists

## Overview

Two major features:

1. **Offline PDF caching** - View charts without internet
2. **Shared setlists** - All setlists visible to all users

---

## Phase 3: Offline PDF Storage

### Behavior

- **Auto-cache**: Every PDF viewed is cached locally
- **TTL**: 7 days, but only evict if fresh version can be fetched

- **Storage**: Unlimited for now - but surface total storage used in the settings menu if that's easy to do.

### Cache Logic

```
On PDF request:
1. Check local cache
2. If cached and < 7 days old → serve from cache
3. If cached and >= 7 days old:
   a. Try to fetch fresh PDF
   b. If success → update cache, serve fresh
   c. If offline → serve stale cache (don't delete)
4. If not cached:
   a. Try to fetch → cache and serve
   b. If offline → show error
```

### Implementation

**New files:**

- `Services/PDFCacheService.swift` - Cache manager

**PDFCacheService responsibilities:**

- Store PDFs in app's Caches directory
- Track metadata (song, key, instrument, cached date) in SQLite or JSON
- Expose: `getCachedPDF()`, `cachePDF()`, `downloadForOffline()`, `clearCache()`
- Background download queue for bulk downloads

**UI changes:**

- Download icon on song cards (filled = cached)
- When you view a setlist, it shows which songs are cached and loads the rest sequentially so they can all be cached.
- Settings: "Cached Songs" count, "Clear Cache" button, total cache used (megabytes or whatever)
- Offline indicator in nav bar when no connection

### Data Model

```swift
struct CachedPDF: Codable {
    let songTitle: String
    let concertKey: String
    let transposition: String
    let clef: String
    let cachedAt: Date
    let filePath: String  // relative to Caches dir
}
```

---

## Phase 4: Shared Setlists

### Behavior

- **All setlists are shared** - No private setlists (for now)
- **All users see all setlists** - Full read/write access for everyone
- **Device ID as identity** - No login required (Apple Sign-In later)
- **Real-time sync** - Fetch on app launch + pull-to-refresh
- **Last write wins** - No conflict resolution
- **No offline editing** - View-only when offline

### Backend Changes

**New endpoints:**

```
GET  /api/v2/setlists              → List all setlists
GET  /api/v2/setlists/:id          → Get single setlist
POST /api/v2/setlists              → Create setlist
PUT  /api/v2/setlists/:id          → Update setlist
DELETE /api/v2/setlists/:id        → Delete setlist
```

**Database schema (SQLite on backend):**

```sql
CREATE TABLE setlists (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by_device TEXT,  -- device ID for future attribution
    deleted_at TIMESTAMP     -- soft delete
);

CREATE TABLE setlist_items (
    id TEXT PRIMARY KEY,
    setlist_id TEXT REFERENCES setlists(id),
    song_title TEXT NOT NULL,
    concert_key TEXT NOT NULL,
    position INTEGER NOT NULL
);
```

### iOS Changes

**SetlistStore updates:**

- Remove UserDefaults persistence
- Add API calls for CRUD
- Store device ID in Keychain (persists across reinstalls)
- Fetch setlists on launch
- Optimistic UI updates + rollback on failure

**New behavior:**

- Pull-to-refresh on SetlistListView
- Loading states for network operations
- Error handling for offline attempts to edit
- "Last updated" timestamp display (optional)

### Device Identity

```swift
// Generate once, store in Keychain
func getOrCreateDeviceID() -> String {
    if let existing = Keychain.get("device_id") {
        return existing
    }
    let new = UUID().uuidString
    Keychain.set("device_id", new)
    return new
}
```

Sent as header: `X-Device-ID: <uuid>`

---

## Implementation Order

### Phase 3 Steps (Offline)

1. Create PDFCacheService with local SQLite/JSON metadata
2. Integrate cache into PDF loading flow
3. Add download button to song cards

4. Add cache info to Settings
5. Add offline indicator

### Phase 4 Steps (Sharing)

1. Backend: Add setlists table + endpoints
2. Backend: Deploy to Fly.io
3. iOS: Add device ID generation
4. iOS: Update SetlistStore to use API
5. iOS: Add pull-to-refresh
6. iOS: Add loading/error states
7. iOS: Migrate existing UserDefaults setlists to server (one-time)

---

## Future Enhancements (Out of Scope)

- Apple Sign-In for proper user accounts
- Private vs public setlist toggle
- Per-user permissions (owner, editor, viewer)
- Invite system with share links
- Real-time WebSocket sync
- Offline editing with sync queue
- Storage limit settings
