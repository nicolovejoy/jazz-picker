# Bands

**Terminology:** UI says "Band", Firestore uses `groups` collection.

Every setlist belongs to a band. Create a solo band for private setlists.

## Rules

- **Joining:** Enter jazz slug code → added as member
- **Leaving:** Can't leave if sole admin (promote someone first)
- **Deleting:** Must be only member, zero setlists

## Invite Flow

- **Copy Invite Link:** Copies message with join URL
- **iOS deep link:** `jazzpicker://join/{code}` - WIP/untested
- **Web:** `?join={code}` query param shows join modal
