# Roadmap

## Completed

**Phase 5: iOS Firebase Auth (Apple Sign-In)**
- [x] Firebase SDK + GoogleService-Info.plist + Sign in with Apple capability
- [x] AuthStore, UserProfileStore, auth UI views
- [x] Integrate with existing app
- [x] Test on device

**Phase 6: iOS Setlists via Firestore**
- [x] Replace Flask backend with Firestore
- [x] Real-time sync with web app
- [x] Unified data model across platforms

## Backlog

- Catalog rebuild with MIDI note ranges (enables auto-octave)
- Setlist "now playing" indicator
- Setlist drag-and-drop reordering (iOS already supports this)
- Remove unused Flask setlist endpoints from app.py

## Design Decisions

- **Shared setlists:** All authenticated users read/write all setlists (2-user band)
- **iOS primary:** Web is secondary client
- **lastOpenedAt:** Local-only on each device (not synced via Firestore)
