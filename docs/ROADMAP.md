# Jazz Picker Roadmap

## Next Up

- Octave offset persistence (server-synced per device+song+key)
- Setlist "now playing" indicator in perform mode

---

## Working

- Browse, search, PDF viewer with edge-tap navigation
- Change Key (12-key picker), Octave +/- (±2 range, local state only)
- Setlists: CRUD, reorder, perform mode, server-synced
- Offline PDF caching (includes octave in cache key)

---

## Backlog

- Octave auto-calculate from note ranges
- Web: decide whether to keep key picker or disable
- Apple Sign-In
- LiteFS for multi-machine consistency

---

## Known Issues

- **Web:** Spin → PDF → close returns to Spin (should return to Browse)
- 2 Fly machines = possible data inconsistency (fine for dev)
