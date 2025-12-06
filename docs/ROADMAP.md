# Jazz Picker Roadmap

## Current State

Phase 4 complete. Setlists sync to server.

**Working:**
- Browse → PDF viewer with edge-tap song navigation
- Change Key with 12-key picker
- Setlists: CRUD, reorder, perform mode (server-synced)
- Offline PDF caching
- Pull-to-refresh, offline detection

---

## Phases

### Phase 1-3: Complete
- Browse, search, PDF viewer
- Setlists with perform mode
- Offline PDF caching

### Phase 4: Shared Setlists ✓
- Server API for setlists
- iOS: optimistic UI, pull-to-refresh, offline detection
- Device ID in Keychain

### Phase 5: Future
- Apple Sign-In
- Private/public setlist toggle
- LiteFS for consistent data across Fly machines

---

## Architecture

- **Stores:** `@Observable` (CatalogStore, SetlistStore, etc.)
- **Setlists:** Server API with optimistic UI
- **Network:** NWPathMonitor for connectivity
- **Auth:** Device ID now → Apple Sign-In later

---

## Known Issues

- **Web:** Spin → PDF → swipe down returns to Spin (should return to Browse with song visible)
- 2 Fly machines = possible data inconsistency (fine for dev)
