# Roadmap

## Backlog

1. Setlist "now playing" indicator (see partner's current song)
2. iOS: Setlist rename

## Design Decisions

- **iOS primary:** Web is secondary client
- **Preferred keys:** Per-user, per-song in Firestore (sparse, only non-defaults)
- **Minor keys:** Display as "F Minor" not "Fm"
- **Terminology:** UI says "Band", Firestore uses `groups` collection
