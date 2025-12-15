# Roadmap

## In Progress

- **Groups/bands** — Phase 1 + 2 done. Run migration, then test. See GROUPS.md.

## Backlog

- Web: Second tap on Setlist nav should go to setlist list (not stay on current setlist)
- Web: Setlist subscription doesn't refresh after creating/joining a group (needs page refresh)
- Web: Create group modal UX glitch (shows create form again instead of success)
- Setlist "now playing" indicator (see partner's current song)
- iOS: Setlist rename functionality
- iOS: Groups UI (after web is working)

## Design Decisions

- **Shared setlists:** All authenticated users share all setlists (temporary, until groups complete)
- **iOS primary:** Web is secondary client
- **Preferred keys:** Per-user, per-song in Firestore. Sparse storage (only non-defaults).
- **Minor keys:** Display as "F Minor" not "Fm"
