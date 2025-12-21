# Groove Sync

Real-time song sharing during gigs. iOS leads, web follows. Leader syncs charts to followers who see them transposed for their instrument.

## Current State (MVP-1)

- iOS can start sharing from setlist detail view
- Web shows join banner, full-screen follower view
- Concert key synced, each follower transposes for their instrument
- No timeout, no delay - immediate sync on song open

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
- `App.tsx` - join banner, follower routing

## Firestore

```
groups/{groupId}/session/current
  - leaderId, leaderName, startedAt, lastActivityAt
  - currentSong: { title, concertKey, source }
```

## Not Yet Implemented

- 3-second delay before sync (avoid noise from quick browsing)
- 5-minute timeout with prompt
- Follower modal when session starts
- Leader sees who's following
- iOS as follower
- Crash/restart persistence
