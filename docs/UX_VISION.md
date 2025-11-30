# Piano House Project: UX Vision & Strategy

## The Big Picture

**Piano House Project** is a platform for musicians to collaborate around music. **Jazz Picker** is the first experience within this platform—a tool for browsing and generating lead sheets from Eric's collection.

Over time, Jazz Picker may include:

- Lead sheet browsing & generation (working today)
- Setlist creation & management (started)
- Collaborative discussions about setlists and arrangements
- Shared links for band communication

## Current State

### What Exists

- **Browse**: Search and filter 735 songs, view cached keys
- **Generate**: Create PDFs in any key for any instrument
- **View**: iPad-optimized PDF viewer with gesture controls
- **Setlists**: Create setlists, view them, remove items, play through in sequence
- **Auth**: Supabase authentication, user accounts

### What's Missing

- **No way to add songs to a setlist** from the UI
- **No dedicated setlist creation flow** - it's just a name and an empty list
- **No collaboration** - no comments, no discussion

---

## Problem Statement: Setlists

### The Gap

Users can create setlists and view them, but there's no intuitive way to populate them with songs. The current mental model is fragmented:

- Browse songs in one mode
- Manage setlists in another mode
- No bridge between them

### Deeper Question

What is a setlist in this context?

---

### Current Priorities

**Phase 1: Complete the Setlist Loop**

- Add songs to setlists (the missing piece)
- Dedicated "create setlist" flow (not just browse + add)
- Shareable setlist links (read-only for non-owners)

**Phase 2: Polish the Core**

- Improve instrument switching UX
- Better onboarding for new users
- Performance mode refinements

---

## Open Questions

### About Setlist Creation

1. When you're building a setlist, do you start with a blank slate and search for songs? Or do you browse and collect songs you like, then arrange them? Answer: can be anything, clone existing and edit, start from scratch, import from someplace.

2. Do you typically create setlists alone, or is it a collaborative process with your band from the start? Can be both.

3. How do you currently share setlist ideas with bandmates? (messy communications of all the usual sorts)

### About the Browsing Experience

4. When browsing, are you usually looking for something specific, or exploring/discovering? (Good question. we want a "spin the wheel" feature on the standard key versions, random selection. Could have a random setlist generated, eventually with filters (singer range, genre, something else))

5. Would you ever want to "favorite" songs independent of setlists? Or is a setlist the only grouping that matters? (Yes, that's a great idea, in an auditable way so I could search for "Favorites from last fall")

### About Performance Mode

6. During a gig, do you ever need to jump to a song not in the setlist? YES.

7. How important is it that setlist songs are pre-loaded/cached for offline use during a gig? Mission critical. Also need bomb proof Do Not Disturb feature.
8.

---

## Next Steps

1. **Discuss** these questions in Antigravity or async
2. **Sketch** the setlist creation flow
3. **Decide** where "add to setlist" lives in the UX
4. **Build** incrementally, test in prod

---

_Last updated: 2024-11-30_
_Status: Vision document, open for discussion_
