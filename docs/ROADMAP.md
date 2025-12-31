# Roadmap

## Backlog

1. Import Eric's "books" as setlists (start with Manine Book)
2. Groove Sync: leader sees who's following
3. Multi-part: Conductor view (all parts stacked)
4. Fix setlist auto-download cancellation (move to background service)

## Future

- Guitar tablature (LilyPond TabStaff)
- Custom chart upload UI (web)
- Per-band song access

## Design Decisions

- iOS primary, web secondary
- Octave offset priority: setlist item > Groove Sync leader > user pref > auto-calc > 0
- Enharmonic spelling context-aware (Gb for flat keys, F# for sharp keys)
- UI says "Band", Firestore uses `groups`
- Groove Sync sessions auto-expire after 15 min inactivity
- PDF viewer controls auto-hide after 5 seconds
