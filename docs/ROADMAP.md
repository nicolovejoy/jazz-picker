# Roadmap

## In Progress

**Phase 5: iOS Firebase Auth (Apple Sign-In)**
- [x] Firebase SDK + GoogleService-Info.plist + Sign in with Apple capability
- [ ] AuthService, UserProfileService, auth UI views
- [ ] Integrate with existing app

## Next

- **Phase 6:** iOS setlists via Firestore (replace Flask)

## Backlog

- Catalog rebuild with MIDI note ranges (enables auto-octave)
- Setlist "now playing" indicator
- Setlist drag-and-drop reordering

## Design Decisions

- **Shared setlists:** All authenticated users read/write all setlists (2-user band)
- **iOS primary:** Web is secondary client
