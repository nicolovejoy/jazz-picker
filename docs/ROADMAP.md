# Roadmap

## In Progress

- **Note range extraction**: Switch to Eric's ambitus log output. See NOTE-RANGE-EXTRACTION.md. Waiting on Eric's confirmation.

## Backlog

- Web: Fix preferred keys bug (`SongListItem.tsx:92` - use `getPreferredKey()` in `handleCardClick()`)
- Web: Add "Add to Setlist" / "Change Key" to PDF viewer menu
- Setlist "now playing" indicator (see partner's current song)
- Note range warnings (need instrument range definitions)
- Groups/bands for multi-user isolation (see GROUPS.md)

## Design Decisions

- **Shared setlists:** All authenticated users share all setlists (2-user band for now)
- **iOS primary:** Web is secondary client
- **Preferred keys:** Per-user, per-song in Firestore. Sparse storage (only non-defaults).
- **Minor keys:** Display as "F Minor" not "Fm"
