# Roadmap

## Backlog

1. Multi-part scores polish (see MULTI_PART_SCORES.md)
   - Add chord symbols from MusicXML `<harmony>` elements
   - Handle repeat signs (currently 23 bars instead of 32)
   - Fix: part subtitle shows user instrument, should show part name
2. Groove Sync Phase 2: timeout, follower modal, leader sees followers
3. iOS Groove Sync follower support
4. iOS: Setlist deep links (`jazzpicker://setlist/{id}`)

## Future

- Guitar tablature output (LilyPond TabStaff)
- Custom chart upload UI (web) - currently manual via CLI
- Per-user/band song access (see MULTI_PART_SCORES.md)

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
- iPad disables idle timer when viewing PDFs (no sleep during gigs)
