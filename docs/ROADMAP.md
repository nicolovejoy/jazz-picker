# Roadmap

## Just Shipped

- **iOS Groups (Bands)** — Create/join/leave/delete bands, setlist filtering by group

## Backlog

- Setlist "now playing" indicator (see partner's current song)
- iOS: Setlist rename functionality
- iOS: Pull-to-refresh for bands
- Phase 4 cleanup: Make groupId required on setlists

## Design Decisions

- **iOS primary:** Web is secondary client
- **Preferred keys:** Per-user, per-song in Firestore. Sparse storage (only non-defaults).
- **Minor keys:** Display as "F Minor" not "Fm"
- **Bands vs Groups:** UI says "Band", Firestore collection is "groups"
