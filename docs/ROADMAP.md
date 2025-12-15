# Roadmap

## Backlog

- Setlist "now playing" indicator (see partner's current song)
- Note range warnings (needs instrument range definitions)
- Groups/bands for multi-user isolation (see GROUPS.md)
- iOS: Setlist rename functionality

## Design Decisions

- **Shared setlists:** All authenticated users share all setlists (2-user band for now)
- **iOS primary:** Web is secondary client
- **Preferred keys:** Per-user, per-song in Firestore. Sparse storage (only non-defaults).
- **Minor keys:** Display as "F Minor" not "Fm"
