# Roadmap

## Backlog

1. Web: Transpose modal needs all 12 keys (currently missing some sharps/flats)
2. iOS: Deep link join (`jazzpicker://join/{code}`) - WIP/untested
3. iOS: Display keys as "C Major" / "C Minor" (not just "C" or "Cm")
4. iOS: Octave not persisting for user preferences (works for setlist items) - P3
5. iOS/Web: Highlight standard key in key picker (bold outline like iReal Pro)

## Post-TestFlight

- Setlist "now playing" indicator (see partner's current song)

## Design Decisions

- **iOS primary:** Web is secondary client
- **Preferred keys:** Per-user, per-song in Firestore (sparse)
- **Minor keys:** Display as "F Minor" not "Fm"
- **Terminology:** UI says "Band", Firestore uses `groups`
- **Band badges:** Only show when user has 2+ bands
- **Landscape width:** Forms/lists use 600pt maxWidth for readability
