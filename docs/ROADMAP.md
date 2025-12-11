# Roadmap

## Backlog

- Sync preferred keys to Firestore (currently local-only UserDefaults)
- Setlist "now playing" indicator (see partner's current song)
- Note range warnings (MIDI data exists, need instrument range definitions)
- Groups/bands for multi-user isolation (see GROUPS.md)

## Design Decisions

- **Shared setlists:** All authenticated users share all setlists (2-user band for now)
- **iOS primary:** Web is secondary client
- **Preferred keys:** Per-user, per-song. Stored locally now; will move to Firestore user profile.
- **Minor keys:** Display as "F Minor" not "Fm"
