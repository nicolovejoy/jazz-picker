# Groove Sync

Real-time song sharing during gigs. iOS leads, web follows. Leader syncs charts to followers who see them transposed for their instrument.

## Current State

- iOS can start sharing from setlist detail view
- Web shows modal when session active, full-screen follower view
- Modal reappears after viewing a PDF if session still active
- Concert key synced, each follower transposes for their instrument
- Immediate sync on song open (no delay)

## Files

**iOS:**
- `GrooveSyncService.swift` - Firestore read/write
- `GrooveSyncStore.swift` - ObservableObject state
- `SetlistDetailView.swift` - "Share Charts" button
- `PDFViewerView.swift` - calls syncSong on load

**Web:**
- `grooveSyncService.ts` - Firestore listener
- `GrooveSyncContext.tsx` - React context
- `GrooveSyncFollower.tsx` - full-screen PDF view
- `GrooveSyncModal.tsx` - join modal
- `App.tsx` - modal display, follower routing

## Firestore

```
groups/{groupId}/session/current
  - leaderId, leaderName, startedAt, lastActivityAt
  - currentSong: { title, concertKey, source }
```

## Not Yet Implemented

- 5-minute timeout with prompt
- Leader sees who's following
- iOS as follower
- Crash/restart persistence
