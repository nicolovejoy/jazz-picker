# Bands Design

**Status:** Complete (iOS + Web). groupId required on all setlists.

**Terminology:** UI says "Band", Firestore uses `groups` collection.

## Overview

Every setlist belongs to a band. No personal setlists (create a solo band if you want privacy).

## Firestore Schema

```
groups/{groupId}
  - name: "Friday Jazz Trio"
  - code: "bebop-monk-cool"  // jazz-themed slug
  - createdAt, updatedAt

groups/{groupId}/members/{userId}
  - role: "admin" | "member"
  - joinedAt: timestamp

setlists/{id}
  - name, ownerId, groupId
  - items: [{ id, songTitle, concertKey, position, octaveOffset, notes }]

users/{uid}
  - instrument, displayName, email
  - preferredKeys: { "Autumn Leaves": "am", ... }
  - groups: ["group123", ...]
  - lastUsedGroupId: "group123"
```

## Band Codes

Jazz-themed slugs, 3 words: `bebop-monk-cool`, `swing-tritone-blue`

## Joining a Band

Code-based: enter the jazz slug → added as member.

## Leaving a Band

- Removes you from member list
- Your setlists stay with the band
- Can't leave if you're the sole admin (unless also sole member with no setlists)

## Deleting a Band

Requirements:
- You must be the only member
- Band must have zero setlists

If setlists exist, user sees: "[Band] has N setlists. Delete them first."

## UX: Leave vs Delete

- **Web:** Leave/Delete buttons with confirmation
- **iOS:** Settings shows band summary, tap to open BandsManagementView with swipe actions

## Members View

Shows display name (or truncated email if no display name set).
