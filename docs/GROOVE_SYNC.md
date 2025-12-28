# Groove Sync

Real-time chart sharing during gigs. iOS can lead or follow. Web can follow.

## How It Works

1. Leader opens setlist, taps "Share Charts"
2. Followers see modal prompt to join
3. As leader opens songs, followers see them auto-transposed for their instrument
4. Sessions auto-expire after 15 minutes of inactivity

## Files

**iOS:**
- `GrooveSyncService.swift` - Firestore read/write, timeout logic
- `GrooveSyncStore.swift` - leader/follower state
- `GrooveSyncModal.swift` - follower join prompt

**Web:**
- `grooveSyncService.ts` - Firestore listener, timeout logic
- `GrooveSyncContext.tsx` - React context
- `GrooveSyncFollower.tsx` - full-screen PDF view

## Firestore

```
groups/{groupId}/session/current
  - leaderId, leaderName, startedAt, lastActivityAt
  - currentSong: { title, concertKey, source, octaveOffset? }
```

## Not Yet Implemented

- Leader sees who's following
