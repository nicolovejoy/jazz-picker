# Roadmap

## In Progress

**iOS Bands swipe actions bug:** Swiping on one band row moves ALL rows and shows duplicate buttons. Current GroupsSection.swift uses standard NavigationLink + swipeActions pattern but something is still broken. Needs fresh investigation.

## Backlog

1. Setlist "now playing" indicator (see partner's current song)
2. iOS: Setlist rename
3. Phase 4 cleanup: Make groupId required on setlists

## Design Decisions

- **iOS primary:** Web is secondary client
- **Preferred keys:** Per-user, per-song in Firestore (sparse, only non-defaults)
- **Minor keys:** Display as "F Minor" not "Fm"
- **Terminology:** UI says "Band", Firestore uses `groups` collection
