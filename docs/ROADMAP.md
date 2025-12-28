# Roadmap

## In Progress

(none)

## Recently Completed

- ~~Transpose Modal: iOS ambitus~~ - Done. Backend now returns `low_note_midi`/`high_note_midi` in catalog API. iOS `AmbitusView` renders range per key.

## Bugs

- ~~Crash on older iPad~~: Fixed. `SetlistFirestoreService.swift:24` had `limit(to: 0)` → changed to `limit(to: 1)`.

## Backlog

1. Groove Sync Phase 2: timeout, leader sees followers
2. Multi-part: Conductor view (all parts stacked for bandleader)
3. Multi-part: UI grouping (part picker instead of separate songs)
4. Transpose Modal: web ambitus + visual polish

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
