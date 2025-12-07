# Plan: Add-to-Setlist with Octave + Conflict Resolution

*2025-12-06*

## Summary

When adding a song from Browse/PDF viewer to a setlist, capture the current octave offset. If the song already exists in the setlist, show a conflict resolution dialog instead of blocking.

## Files to Modify

| File | Change |
|------|--------|
| `JazzPicker/Views/PDF/PDFViewerView.swift` | Pass `octaveOffset` to AddToSetlistSheet |
| `JazzPicker/Views/Setlists/AddToSetlistSheet.swift` | Accept octaveOffset, add conflict dialog |
| `JazzPicker/Services/SetlistStore.swift` | Update `addSong()` to accept octaveOffset |

## Implementation Steps

### 1. AddToSetlistSheet - Add octaveOffset parameter
```swift
let songTitle: String
let concertKey: String
let octaveOffset: Int  // NEW
```

### 2. PDFViewerView - Pass octaveOffset
```swift
// Line ~235
AddToSetlistSheet(songTitle: song.title, concertKey: concertKey, octaveOffset: octaveOffset)
```

### 3. SetlistStore.addSong - Accept octaveOffset
```swift
func addSong(to setlist: Setlist, songTitle: String, concertKey: String, octaveOffset: Int = 0) async throws
```

Update the optimistic item creation:
```swift
let item = SetlistItem(songTitle: songTitle, concertKey: concertKey, position: position, octaveOffset: octaveOffset)
```

### 4. AddToSetlistSheet - Conflict Resolution

Replace the disabled-if-exists logic with:

**State:**
```swift
@State private var conflictSetlist: Setlist?
@State private var existingItem: SetlistItem?
```

**When tapping a setlist that contains the song:**
- Find the existing item
- Set `conflictSetlist` and `existingItem`
- Show `.confirmationDialog`

**Dialog UI:**
```
"Blue Bossa" is already in this setlist

Existing: Bb (+1 oct)
New: C (0 oct)

[Replace] [Keep Existing] [Cancel]
```

**Actions:**
- **Replace**: Remove old item, add new one with current key/octave
- **Keep Existing**: Dismiss sheet, no changes

(No "Add Both" - duplicates not allowed)

### 5. SetlistStore - Add replaceItem helper (optional)
```swift
func replaceItem(in setlist: Setlist, oldItem: SetlistItem, with newItem: SetlistItem) async throws
```

Or reuse existing `removeItem` + `addSong`.

## Edge Cases
- Same song, same key, same octave → could skip the dialog entirely
- Network offline → show existing offline toast

## Testing
1. Open song from Browse, change key + octave
2. Add to setlist that doesn't have it → should save with key + octave
3. Add to setlist that has it → conflict dialog appears
4. Choose Replace → old item removed, new added
5. Choose Keep Existing → nothing changes
