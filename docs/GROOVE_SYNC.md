# Groove Sync

Real-time chart sharing during gigs. iOS can lead or follow. Web can follow.

## How It Works

1. Leader starts sharing from setlist OR any PDF viewer (toolbar → "Share with Band")
2. Followers see modal prompt to join
3. As leader opens songs, followers see them auto-transposed for their instrument
4. Sessions auto-expire after 15 minutes of inactivity

## Page 2 Mode

Follower option (off by default). When enabled, follower sees leader's page + 1. For page turners or second music stands.

- Toggle in Groove Sync join modal or Settings → Groove Sync
- Blank screen shown when: leader on last page OR single-page chart
- Stored in UserDefaults (local preference, not synced)

## Files

**iOS:**
- `GrooveSyncService.swift` - Firestore read/write, timeout logic
- `GrooveSyncStore.swift` - leader/follower state, page sync with 100ms debounce
- `GrooveSyncModal.swift` - follower join prompt with Page 2 toggle
- `QuickBandPickerSheet.swift` - band picker for starting from PDF viewer
- `FollowerPDFContainerView.swift` - smooth transitions between charts
- `BlankPageView.swift` - shown when Page 2 mode has no next page

**Web:**
- `grooveSyncService.ts` - Firestore listener, timeout logic
- `GrooveSyncContext.tsx` - React context
- `GrooveSyncFollower.tsx` - full-screen PDF view

## Firestore

```
groups/{groupId}/session/current
  - leaderId, leaderName, startedAt, lastActivityAt
  - currentSong: { title, concertKey, source, octaveOffset?, currentPage, pageCount }
```

## Not Yet Implemented

- Leader sees who's following
- Web Page 2 mode support
