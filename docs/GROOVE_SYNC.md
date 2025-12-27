# Groove Sync

Real-time chart sharing during gigs. iOS can lead or follow. Web can follow.

## How It Works

1. Leader opens setlist, taps "Share Charts"
2. Followers see modal prompt to join
3. As leader opens songs, followers see them auto-transposed for their instrument

## Files

**iOS:**
- `GrooveSyncService.swift` - Firestore read/write
- `GrooveSyncStore.swift` - leader/follower state
- `GrooveSyncModal.swift` - follower join prompt
- `SetlistDetailView.swift` - "Share Charts" button
- `ContentView.swift` - follower integration

**Web:**
- `grooveSyncService.ts` - Firestore listener
- `GrooveSyncContext.tsx` - React context
- `GrooveSyncFollower.tsx` - full-screen PDF view
- `GrooveSyncModal.tsx` - join modal

## Firestore

```
groups/{groupId}/session/current
  - leaderId, leaderName, startedAt, lastActivityAt
  - currentSong: { title, concertKey, source, octaveOffset? }
```

## Not Yet Implemented

- 5-minute timeout with prompt
- Leader sees who's following
