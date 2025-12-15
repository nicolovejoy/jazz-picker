# Roadmap

## In Progress

- **Groups/bands** — Phase 1 + 2 done. Run migration, then test. See GROUPS.md.

## Backlog

- Setlist "now playing" indicator (see partner's current song)
- iOS: Setlist rename functionality
- iOS: Groups UI (after web is working)

## Design Decisions

- **Shared setlists:** All authenticated users share all setlists (temporary, until groups complete)
- **iOS primary:** Web is secondary client
- **Preferred keys:** Per-user, per-song in Firestore. Sparse storage (only non-defaults).
- **Minor keys:** Display as "F Minor" not "Fm"
