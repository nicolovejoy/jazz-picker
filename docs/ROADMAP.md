# Roadmap

## In Progress

**Firebase Auth + Firestore Migration** ([plan](FIREBASE_AUTH_PLAN.md))
- [x] Phase 1: Web auth (Apple, Google, email)
- [ ] Phase 2: Flask token verification
- [ ] Phase 3: Firestore user profiles + instrument
- [ ] Phase 4: Firestore setlists
- [ ] Phase 5: iOS auth

## Backlog

- Rebuild catalog with MIDI note ranges (enables auto-octave)
- Setlist "now playing" indicator

## Working

- Browse, search, PDF viewer with edge-tap navigation
- Change Key (12-key picker), Octave +/- (±2 range)
- Auto-octave calculation (backend deployed, needs catalog rebuild)
- Setlists: CRUD, reorder, server-synced with key/octave
- Add-to-Setlist from PDF viewer (iOS + Web)
- Offline PDF caching
