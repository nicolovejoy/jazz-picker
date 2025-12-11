# Roadmap

## In Progress

- **Web preferred keys bug**: Reads from Firestore correctly, but song tap uses default key instead of preferred. Fix in `SongListItem.tsx:92` - use `getPreferredKey()` in `handleCardClick()`.

## Backlog

- Web: Simplify song card UI (match iOS style)
- Web: Add "Add to Setlist" / "Change Key" to PDF viewer menu
- Setlist "now playing" indicator (see partner's current song)
- Note range warnings (MIDI data exists, need instrument range definitions)
- Groups/bands for multi-user isolation (see GROUPS.md)

## Design Decisions

- **Shared setlists:** All authenticated users share all setlists (2-user band for now)
- **iOS primary:** Web is secondary client
- **Preferred keys:** Per-user, per-song in Firestore. Sparse storage (only non-defaults).
- **Minor keys:** Display as "F Minor" not "Fm"
