# Jazz Picker Roadmap

## Next Up

- Setlist "now playing" indicator in perform mode

---

## Working

- Browse, search, PDF viewer with edge-tap navigation
- Change Key (12-key picker), Octave +/- (±2 range)
- Setlists: CRUD, reorder, perform mode, server-synced
- Offline PDF caching (includes octave in cache key)
- **Blocked:** Octave persistence (see Known Issues)

---

## Backlog

- Octave auto-calculate from note ranges
- Web: decide whether to keep key picker or disable
- Apple Sign-In
- LiteFS for multi-machine consistency

---

## Known Issues

- **Octave persistence blocked:** 2 Fly machines with separate SQLite. Fix: `fly scale count 1` or migrate to Postgres. See [INFRASTRUCTURE.md](INFRASTRUCTURE.md).
- **Web:** Spin → PDF → close returns to Spin (should return to Browse)
