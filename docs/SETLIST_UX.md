# Setlist & Key Management UX

## Terminology

- **Standard key**: Original key of a song (from catalog)
- **Concert key**: Key being performed

---

## PDF Viewer

### Controls (auto-hide after 1.5s)

- **Top bar**: X (close), song title, key, menu (•••)
- **Bottom right**: "3/10" in setlist perform mode (informational only)

Appear on: open, tap screen
Do NOT appear on: swipe between songs

### Close

- Swipe down, OR
- Tap X in top bar

### Menu Options

1. **Change Key** — circle-of-fifths wheel picker (bottom sheet, drag to spin, Confirm in center)
2. **Add to Setlist** — adds at current key

### Add to Setlist Flow

- Shows list of setlists + "New Setlist..."
- Adds song at **current key** (no standard key option)
- If non-standard key: warn "Saving in [key] (standard is [key])"
- Song added to end
- Toast: "Added to Friday Gig"

---

## Setlists Tab

### List View

- Cards ordered by most recently opened
- Card shows: name + song titles (as many as fit)
- Swipe to delete → **confirm dialog**
- "+" creates new setlist (modal with name field)

### Empty State

"No Setlists" + prominent "Create Setlist" button

---

## Setlist Detail

### Song List (default)

- Rows: song title + concert key
- Tap song → Perform Mode (PDF viewer at that song)
- Swipe to delete song (no confirmation)

### Perform Mode

- Swipe left/right through songs sequentially
- Same PDF viewer controls
- "3/10" indicator shows position

### Edit Mode

- Drag handles for reordering
- Multi-select → "New Setlist from Selected"
- Insert **Set Break** between songs
- Delete songs

---

## Data Model

```swift
struct Setlist: Codable, Identifiable {
    let id: UUID
    var name: String
    var items: [SetlistItem]
    var createdAt: Date
    var lastOpenedAt: Date
    var deletedAt: Date?  // Soft delete
}

struct SetlistItem: Codable, Identifiable {
    let id: UUID
    var songTitle: String      // Empty for set breaks
    var concertKey: String
    var position: Int
    var isSetBreak: Bool       // True = divider, not a song
}
```

### Constraints

- One instance per song per setlist
- Same song can be in multiple setlists at different keys

### Storage

- iCloud (NSUbiquitousKeyValueStore)
- Soft deletes retained for future recovery

---

## First Two Implementation Steps

### Step 1: Setlist Data Layer

- Create `Setlist` and `SetlistItem` models
- Create `SetlistStore` (ObservableObject) with CRUD operations
- Local persistence first (UserDefaults), iCloud later
- Include soft delete support

### Step 2: Setlists Tab UI

- `SetlistListView` with cards (name + song previews)
- Empty state with "Create Setlist" button
- Create setlist modal (name input)
- Swipe to delete with confirmation
- Sort by `lastOpenedAt`

---

## Future (Out of Scope)

- Spin from setlist
- Sharing setlists between users
- Un-delete UI
- Tap "3/10" to jump
