# Roadmap

## In Progress

**Firebase Auth + Firestore Migration**
- [x] Phase 1: Web auth (Apple, Google, email)
- [x] Phase 2: Flask token verification
- [x] Phase 3: Firestore user profiles + instrument
- [x] Phase 4: Firestore setlists (Web) - real-time sync, offline support
- [ ] Phase 5: iOS auth (Apple Sign-In + Firestore)

## Backlog

- Rebuild catalog with MIDI note ranges (enables auto-octave)
- Setlist "now playing" indicator
- Setlist reordering UI (drag-and-drop)

## Working

- Browse, search, PDF viewer with edge-tap navigation
- Change Key (12-key picker), Octave +/- (±2 range)
- Auto-octave calculation (backend deployed, needs catalog rebuild)
- Setlists: CRUD, real-time sync, offline support (Web)
- Add-to-Setlist from PDF viewer (iOS + Web)
- Offline PDF caching
- Web: Required sign-in, Firestore user profiles with instrument sync
