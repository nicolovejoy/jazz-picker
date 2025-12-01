# Session Handoff - Nov 30, 2025 (Night)

## Completed This Session

**Multi-Context App Architecture:**
- Shifted from single-hub (song list) to 4-context navigation
- Bottom nav with: Browse, Spin (placeholder), Setlist, More
- Each context is self-contained, nav is ubiquitous and minimal

**Header Redesign:**
- Slim fixed header matching bottom nav style (h-14)
- Layout: "Jazz Picker" (left) | Search bar 55% centered | Build date (right)
- Auto-focus on search input

**Song Card Improvements:**
- Cleaner single-row layout: title + key pills
- Tap card → opens PDF in default key
- Hover (desktop) or long-press (touch) → reveals action buttons
- Action buttons: Add to Setlist (+), Custom Key (♪)
- Loading states: "Loading from cache..." or "Generating from LilyPond..."
- Larger cards (~20% bigger), fewer per screen

**PWA Fullscreen:**
- `black-translucent` status bar style for true fullscreen
- Safe area handling for notches
- Fixed body prevents overscroll bounce

**Menu Context:**
- Cleaner settings page with instrument, about, sign out
- Version info at bottom

---

## Current State

**Live URLs:**
- Frontend: https://pianohouseproject.org (soon: jazzpick.pianohouseproject.org)
- Backend: https://jazz-picker.fly.dev

**Navigation (Bottom Nav):**
| Tab | Purpose |
|-----|---------|
| Browse | Search songs, view PDFs, add to setlist |
| Spin | Random song mode (placeholder) |
| Setlist | View/edit setlists |
| More | Settings, about, sign out |

**What Works:**
- 4-context navigation with bottom nav
- Slim header with search
- Song cards with hover/long-press actions
- Add to Setlist modal
- Setlist manager and viewer
- Shareable setlist URLs
- PDF viewer with setlist navigation
- PWA fullscreen mode
- Multi-instrument support

---

## What's Next

**Priority (per UX_VISION.md):**
1. Setlist Edit mode (drag-drop, search-to-add, key +/-)
2. Spin the Dial context
3. Browse → PDF navigation (arrows/swipe between songs)
4. URL rename to jazzpick.pianohouseproject.org

**Future Ideas:**
- Offline/cached PDFs for gigs
- Favorites (auditable, searchable)
- Do Not Disturb mode for performances

---

## Key Files Changed

```
frontend/src/
├── components/
│   ├── BottomNav.tsx      # 4-context nav (browse, spin, setlist, menu)
│   ├── Header.tsx         # Slim header with search
│   ├── SongListItem.tsx   # Hover/long-press actions, loading states
│   └── SongList.tsx       # 1-2 column layout
├── App.tsx                # Context switching, Menu view
└── index.css              # PWA fullscreen styles

docs/
└── UX_VISION.md           # Updated with multi-context architecture
```

---

## Technical Notes

- `AppContext` type: `'browse' | 'spin' | 'setlist' | 'menu'`
- Touch detection via `isTouch.current` ref to handle hover vs long-press
- Build time hardcoded in Header (could be automated via Vite)
- Cards use `cachedConcertKeys.includes()` to determine loading message
