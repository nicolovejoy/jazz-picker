# Roadmap

## Backlog

1. iOS: Setlist deep links (`jazzpicker://setlist/{id}`)
2. Setlist "now playing" indicator (see partner's current song)

## Future

- Custom chart upload UI (web) - currently manual via CLI
- Multi-part charts (bass, piano - Eric's format supports this)

## Design Decisions

- iOS primary, web secondary
- Preferred keys per-user, per-song in Firestore (sparse)
- Song cards show: standard key (gray) + preferred key (orange parens) when different
- Key picker highlights standard key with bold outline
- Enharmonic spelling context-aware (Gb for flat keys, F# for sharp keys)
- Minor keys display as "F Minor" not "Fm"
- UI says "Band", Firestore uses `groups`
- Band badges only show when user has 2+ bands
- Landscape forms/lists use 600pt maxWidth
