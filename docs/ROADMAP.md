# Roadmap

## Backlog

1. Groove Sync Phase 2: timeout, leader sees followers
2. iOS Groove Sync follower support
3. Multi-part: Conductor view (all parts stacked for bandleader)
4. Multi-part: UI grouping (part picker instead of separate songs)
5. iOS: Setlist deep links (`jazzpicker://setlist/{id}`)

## Future

- Guitar tablature output (LilyPond TabStaff)
- Custom chart upload UI (web)
- Per-user/band song access

## Design Decisions

- iOS primary, web secondary
- Preferred keys per-user, per-song in Firestore (sparse)
- Octave offset priority: setlist item > Groove Sync leader > user preference > auto-calc > 0
- Song cards show: standard key (gray) + preferred key (orange parens) when different
- Key picker highlights standard key with bold outline
- Enharmonic spelling context-aware (Gb for flat keys, F# for sharp keys)
- Minor keys display as "F Minor" not "Fm"
- UI says "Band", Firestore uses `groups`
- Band badges only show when user has 2+ bands
- Landscape forms/lists use 600pt maxWidth
- iPad disables idle timer when viewing PDFs (no sleep during gigs)
