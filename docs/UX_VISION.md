# Piano House Project: UX Vision & Strategy

## The Big Picture

**Piano House Project** is a platform for musicians to prepare, perform, and collaborate around music. **Jazz Picker** is the first experience within this platform—a tool for browsing and generating lead sheets from Eric's collection.

Over time, Piano House Project may include:
- Lead sheet browsing & generation (Jazz Picker - current)
- Setlist creation & management
- Practice session recordings
- Live performance recordings
- Collaborative discussions about setlists and arrangements
- Annotations and comments on charts
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
- **No sharing** - setlists are private to each user
- **No collaboration** - no comments, no discussion

---

## Problem Statement: Setlists

### The Gap
Users can create setlists and view them, but there's no intuitive way to populate them with songs. The current mental model is fragmented:
- Browse songs in one mode
- Manage setlists in another mode
- No bridge between them

### Deeper Question
What is a setlist in the context of Piano House Project?

**Option A: Gig Prep Tool**
- Created days/weeks before a performance
- Curated carefully, reordered, discussed with bandmates
- Shared via link for others to review
- The "product" is a ready-to-perform song order

**Option B: Live Performance Companion**
- Quick access during a gig
- Swipe through songs in order
- Minimal friction, maximum focus
- The "product" is seamless chart access on stage

**Option C: Both** (likely answer)
- Prep mode: creative, collaborative, shareable
- Performance mode: focused, streamlined, distraction-free

---

## Long-Term Vision

### User Journey (Future State)

```
1. DISCOVER
   Browse charts, search, explore keys

2. PREPARE
   Create setlists for upcoming gigs
   Reorder songs, discuss with band
   Share links for feedback

3. PRACTICE
   Record practice sessions
   Annotate charts with notes
   Review recordings

4. PERFORM
   Setlist performance mode
   Minimal UI, gesture navigation
   Record live performances

5. REFLECT
   Review recordings
   Share highlights
   Discuss what worked
```

### Platform Architecture

```
Piano House Project (pianohouseproject.org)
├── Jazz Picker (lead sheets)
│   ├── Browse & Search
│   ├── Generate Charts
│   └── View PDFs
├── Setlists
│   ├── Create & Edit
│   ├── Share & Discuss
│   └── Perform Mode
├── Recordings (future)
│   ├── Practice Sessions
│   └── Live Performances
└── Social (future)
    ├── Comments on Charts
    ├── Setlist Discussions
    └── Band Messaging
```

---

## UX Strategy

### Principles

1. **Modes, not features** - Users should feel like they're in a coherent experience (browsing, creating, performing), not jumping between disconnected features

2. **Progressive disclosure** - Start simple, reveal complexity as needed. A new user should feel welcomed, not overwhelmed

3. **Offline-first collaboration** - For now, sharing = generating a link. No in-app messaging. Users text/email each other with links to shared setlists

4. **Performance mode is sacred** - When performing, zero friction. Everything else fades away

### Current Priorities

**Phase 1: Complete the Setlist Loop**
- Add songs to setlists (the missing piece)
- Dedicated "create setlist" flow (not just browse + add)
- Shareable setlist links (read-only for non-owners)

**Phase 2: Polish the Core**
- Improve instrument switching UX
- Better onboarding for new users
- Performance mode refinements

**Phase 3: Expand the Platform**
- Piano House Project branding/framing
- Recordings (practice sessions)
- Basic annotations on charts

---

## Open Questions

### About Setlist Creation
1. When you're building a setlist, do you start with a blank slate and search for songs? Or do you browse and collect songs you like, then arrange them?

2. Do you typically create setlists alone, or is it a collaborative process with your band from the start?

3. How do you currently share setlist ideas with bandmates? (Text? Email? Shared doc?)

### About the Browsing Experience
4. When browsing, are you usually looking for something specific, or exploring/discovering?

5. Would you ever want to "favorite" songs independent of setlists? Or is a setlist the only grouping that matters?

### About Performance Mode
6. During a gig, do you ever need to jump to a song not in the setlist? (Audience request, audible, etc.)

7. How important is it that setlist songs are pre-loaded/cached for offline use during a gig?

---

## Next Steps

1. **Discuss** these questions in Antigravity or async
2. **Sketch** the setlist creation flow
3. **Decide** where "add to setlist" lives in the UX
4. **Build** incrementally, test in prod

---

*Last updated: 2024-11-30*
*Status: Vision document, open for discussion*
