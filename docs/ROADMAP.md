# Roadmap

## Backlog

1. Web: Duplicate setlist
2. Web: Render set breaks (currently shows empty card)
3. iOS: Deep link join (`jazzpicker://join/{code}`) - WIP/untested

## Post-TestFlight

- Setlist "now playing" indicator (see partner's current song)

## Design Decisions

- **iOS primary:** Web is secondary client
- **Preferred keys:** Per-user, per-song in Firestore (sparse)
- **Minor keys:** Display as "F Minor" not "Fm"
- **Terminology:** UI says "Band", Firestore uses `groups`
- **Band badges:** Only show when user has 2+ bands
- **Landscape width:** Forms/lists use 600pt maxWidth for readability
