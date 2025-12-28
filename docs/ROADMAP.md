# Roadmap

## Backlog

1. Groove Sync Phase 2: timeout, leader sees followers
2. Multi-part: Conductor view (all parts stacked)
3. Multi-part: UI grouping (part picker instead of separate songs)
4. Web ambitus display

## Future

- Guitar tablature (LilyPond TabStaff)
- Custom chart upload UI (web)
- Per-band song access

## Design Decisions

- iOS primary, web secondary
- Octave offset priority: setlist item > Groove Sync leader > user pref > auto-calc > 0
- Enharmonic spelling context-aware (Gb for flat keys, F# for sharp keys)
- UI says "Band", Firestore uses `groups`
