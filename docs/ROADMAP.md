# Roadmap

## Backlog

1. iOS: Test deep link join (`jazzpicker://join/{code}`)
2. iOS: Print PDF
3. Web: Transpose modal - all 12 keys (missing some sharps/flats)
4. iOS/Web: Highlight standard key in key picker (bold outline)
5. Setlist "now playing" indicator (see partner's current song)

## Future

- Custom chart upload UI (web) - currently manual via CLI
- Multi-part charts (bass, piano - Eric's format supports this)

## Design Decisions

- iOS primary, web secondary
- Preferred keys per-user, per-song in Firestore (sparse)
- Song cards show: standard key (gray) + preferred key (orange parens) when different
- Minor keys display as "F Minor" not "Fm"
- UI says "Band", Firestore uses `groups`
- Band badges only show when user has 2+ bands
- Landscape forms/lists use 600pt maxWidth
