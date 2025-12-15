# Groups Design

**Status:** Phase 1 + 2 complete. Web working. Phase 3 (iOS) next.

## Overview

Replacing the current "all users share everything" model with groups (bands). Every setlist belongs to a group. No personal setlists (create a solo group if you want privacy).

## Firestore Schema

```
groups/{groupId}
  - name: "Friday Jazz Trio"
  - code: "bebop-monk-cool"  // jazz-themed slug, visible to all members
  - createdAt, updatedAt

groups/{groupId}/members/{userId}
  - role: "admin" | "member"  // creator is admin, can delegate
  - joinedAt: timestamp

setlists/{id}
  - name, createdAt, updatedAt
  - ownerId: "user123"  // creator (audit trail)
  - groupId: "group123"  // required, every setlist belongs to a group
  - items: [{ id, songTitle, concertKey, position, octaveOffset, notes }]

users/{uid}
  - instrument, displayName
  - preferredKeys: { "Autumn Leaves": "am", ... }  // sparse
  - groups: ["group123", "group456"]  // denormalized for quick lookup
  - lastUsedGroupId: "group123"  // for default group selection

auditLog/{logId}
  - groupId, action, actorId, targetId, timestamp, metadata
  - actions: member_joined, member_left, member_removed, admin_granted, admin_revoked
```

## Group Codes

Jazz-themed slugs from ~1000 word list, 3 words combined:
- `bebop-monk-cool`, `swing-tritone-blue`, `modal-keys-midnight`
- Categories: styles, musicians, terms, instruments, feel words
- ~1 billion combinations (collision-resistant)
- All members can see and share the code

## Group Selection UX

When creating a setlist (user in multiple groups):
1. Default to last-used group
2. Show up to 3 most recent groups
3. "More options" for additional groups

## Admin Model

- Creator is admin
- Admin can delegate admin to others
- Admin can remove members (placeholder for MVP)
- Can't leave group if you're the sole admin
- When leaving: most senior admin inherits ownership

## Joining Groups

MVP: Code-based (know the code = you're in)
- Enter jazz slug → added as member
- No approval flow needed

## Preferred Keys

Unchanged from current behavior:
- Per-user, per-song in Firestore (sparse storage)
- Setlist items carry their own concert key
- No group-level preferred keys

## Leaving a Group

- Can't leave if sole admin
- Setlists you created stay with the group
- Most senior admin becomes owner of orphaned resources

## Implementation Phases

### Phase 1: Backend / Firestore
- Groups collection + members subcollection
- Add groupId to setlists (nullable initially)
- Add groups[] and lastUsedGroupId to users
- Security rules
- Jazz slug generator

### Phase 2: Web MVP
- Create/join group flows
- Group switcher UI
- Filtered setlist views
- Member list

### Phase 3: iOS Port
- Port all group functionality

### Phase 4: Cleanup
- Make groupId required
- Remove legacy shared-everything code
