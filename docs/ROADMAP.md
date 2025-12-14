# Roadmap

## Recently Completed

- **Note range extraction**: Now using Eric's pre-parsed `range-data.txt`. See NOTE-RANGE-EXTRACTION.md.

## Backlog

- Web: Preferred keys enhancement (see WEB-PREFERRED-KEYS.md)
- Setlist "now playing" indicator (see partner's current song)
- Note range warnings (need instrument range definitions)
- Groups/bands for multi-user isolation (see GROUPS.md)

## Design Decisions

- **Shared setlists:** All authenticated users share all setlists (2-user band for now)
- **iOS primary:** Web is secondary client
- **Preferred keys:** Per-user, per-song in Firestore. Sparse storage (only non-defaults).
- **Minor keys:** Display as "F Minor" not "Fm"
