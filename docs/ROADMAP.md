# Roadmap

## Backlog

1. iOS: Test deep link join (`jazzpicker://join/{code}`)
2. Web: Transpose modal needs all 12 keys (missing some sharps/flats)
3. iOS/Web: Highlight standard key in key picker (bold outline like iReal Pro)
4. iOS: Display keys as "C Major" / "C Minor" (not just "C" or "Cm")

## Post-TestFlight

- Setlist "now playing" indicator (see partner's current song)
- Custom chart upload UI (web)
- Multi-part charts (bass, piano - Eric's format supports this)

## Design Decisions

- **iOS primary:** Web is secondary client
- **Preferred keys:** Per-user, per-song in Firestore (sparse)
- **Minor keys:** Display as "F Minor" not "Fm"
- **Terminology:** UI says "Band", Firestore uses `groups`
- **Band badges:** Only show when user has 2+ bands
- **Landscape width:** Forms/lists use 600pt maxWidth
