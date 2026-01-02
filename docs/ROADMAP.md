# Roadmap

## Pending

- Rebrand to "AnyKey" (awaiting Eric/James feedback) - see `VISION.md`

## Backlog

1. Import Eric's "books" as setlists (start with Manine Book)
2. Groove Sync: leader sees who's following
3. Multi-part: Conductor view (all parts stacked)
4. Fix setlist auto-download cancellation (move to background service)

## Future

- Composition workflow: MIDI/Logic → MusicXML → LilyPond → app
- Guitar tablature (LilyPond TabStaff)
- Custom chart upload UI (web)
- Per-band song access

## Design Decisions

- iOS primary, web secondary
- Octave offset priority: setlist item > Groove Sync leader > user pref > auto-calc > 0
- Enharmonic spelling context-aware (Gb for flat keys, F# for sharp keys)
- UI says "Band", Firestore uses `groups`
- Groove Sync sessions auto-expire after 15 min inactivity
- PDF viewer timeouts: 5s controls, 10s metronome, 30s settings, 30min idle
