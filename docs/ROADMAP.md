# Roadmap

## Next Up

**Firebase Auth (Phase 1: iOS)**
- Create Firebase project
- Configure Apple Sign-In
- Add AuthService to iOS app
- Update backend to verify tokens

See [FIREBASE_AUTH_PLAN.md](FIREBASE_AUTH_PLAN.md) for detailed steps.

---

## Working

- Browse, search, PDF viewer with edge-tap navigation
- Change Key (12-key picker), Octave +/- (range)
- Setlists: CRUD, reorder, perform mode, server-synced
- Offline PDF caching (includes octave in cache key)
- Octave persistence (still broken - scaled to 1 machine but not yet working)

---

## Backlog

- Firebase Auth (Phase 2: Web) - email/password for non-Apple users
- Setlist "now playing" indicator in perform mode
- Octave auto-calculate from note ranges

---

## Done

- **2025-12-06:** Scaled Fly to 1 machine (SQLite consistency fix attempted, octave persistence still broken)

---

## Known Issues

- **Web:** Spin -> PDF -> close returns to Spin (should return to Browse)
