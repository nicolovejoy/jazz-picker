# Jazz Picker Roadmap

## Next Up: Octave Offset (iOS)

Key transposition sometimes renders charts an octave too high/low.

**Plan:** `.claude/plans/snazzy-prancing-locket.md`

- Manual octave +/- buttons in PDF viewer menu
- Server-synced per device+song+key
- Auto-calculate (fewest ledger lines) comes later

---

## Working

- Browse, search, PDF viewer with edge-tap navigation
- Change Key (12-key picker)
- Setlists: CRUD, reorder, perform mode, server-synced
- Offline PDF caching, pull-to-refresh, offline detection

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
