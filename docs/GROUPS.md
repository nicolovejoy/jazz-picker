# Groups Design

**Status:** Design document only - not implementing now.

## Overview

Replacing the current "all users share everything" model with groups (bands). Each group has members and setlists.

## Firestore Schema

```
groups/{groupId}
  - name: "Friday Jazz Trio"
  - createdAt, updatedAt

groupMembers/{groupId}/members/{userId}
  - joinedAt
  - role: "member" | "admin"  // admin = creator, can delete group

setlists/{id}
  - name, createdAt, updatedAt
  - ownerId: "user123"  // creator, always set
  - groupId: "group123" | null  // null = personal setlist, not shared
  - items: [{ id, songTitle, concertKey, position, octaveOffset, notes }]

users/{uid}
  - instrument, displayName
  - preferredKeys: { "Autumn Leaves": "am", ... }  // sparse: only stores overrides from default key
  - groups: ["group123", "group456"]  // for quick lookup
```

## Preferred Keys

**Two sources of keys:**
1. **Setlist item key**: The key for a specific song in a specific setlist (stored in setlist item)
2. **User preferred key**: The last key a user viewed a song in (stored per-user, per-song)

**Behavior:**
- Viewing from setlist → shows setlist item's key → also updates user's preferred key
- Viewing from browse → shows user's preferred key (or default if none set)
- Changing key while browsing → updates user's preferred key
- Changing key while in setlist → updates both setlist item AND user's preferred key

**No group preferred keys.** Groups own setlists; setlist items carry the keys.

**Sparse storage:** User's `preferredKeys` map only stores keys that differ from the song's default. If not present, use the song's default key from catalog.

## Setlist Ownership

- Personal setlist: `groupId = null`, only visible to owner
- Group setlist: `groupId` set, visible to all group members
- When creating setlist, user picks personal or which group (if in multiple)
- `ownerId` always tracks creator (for personal setlists and audit trail)

## Sharing & Copying

- Share setlist outside group → creates independent copy for recipient's group
- Copy within group → creates independent copy
- Copies are fully independent - no sync between them

## Joining Groups

- User requests to join a group (by code or search)
- Admin approves request → user added to group
- Future: invite by email

## Migration Path

**Phase 1:** Preferred keys in Firestore. Done (iOS and web).

**Phase 2:** Add groups. Migrate existing users:
- Create a default group for existing users who share setlists
- Move their setlists to that group

## Open Questions

- Group deletion - what happens to group setlists? Delete? Convert to personal for owner?
- Leave group - do group setlists you created stay with the group or come with you?
