# Jazz Picker Native Swift Architecture

## Overview

Native SwiftUI app replacing the Capacitor/React hybrid. iPad-first, with native Mac support added later (SwiftUI multiplatform, not Catalyst).

**Key decisions:**
- Setlists sync via iCloud (CloudKit)
- Offline mode: pre-download setlist PDFs
- Catalog cached locally with periodic refresh
- No auth for v1 (Sign in with Apple later)

---

## Project Structure

```
JazzPicker/
├── App/
│   ├── JazzPickerApp.swift          # @main entry point
│   └── ContentView.swift            # Root view with tab navigation
│
├── Models/
│   ├── Song.swift                   # Song model (title, default_key, note range)
│   ├── Setlist.swift                # Setlist + SetlistItem models
│   └── Instrument.swift             # Instrument enum with transposition logic
│
├── Views/
│   ├── Browse/
│   │   ├── BrowseView.swift         # Song list with search
│   │   └── SongRow.swift            # Individual song row with key pills
│   │
│   ├── Setlist/
│   │   ├── SetlistListView.swift    # List of setlists
│   │   ├── SetlistDetailView.swift  # Songs in a setlist (perform mode)
│   │   └── SetlistEditView.swift    # Drag to reorder, add/remove songs
│   │
│   ├── PDF/
│   │   └── PDFViewerView.swift      # SwiftUI wrapper for PDFKit
│   │
│   ├── Settings/
│   │   └── SettingsView.swift       # Instrument picker, about
│   │
│   └── Components/
│       ├── KeyPill.swift            # Concert key badge
│       ├── SpinButton.swift         # Roulette action button
│       └── LoadingOverlay.swift     # PDF loading state
│
├── Services/
│   ├── APIClient.swift              # Network layer (async/await)
│   ├── CatalogStore.swift           # Local catalog cache
│   ├── PDFCache.swift               # Downloaded PDF management
│   └── CloudKitManager.swift        # iCloud setlist sync
│
├── Utilities/
│   ├── KeyTransposer.swift          # Concert ↔ written key math
│   └── Constants.swift              # API URLs, cache keys
│
└── Resources/
    └── Assets.xcassets              # App icon, colors
```

---

## Data Flow

### Catalog

```
┌─────────────┐     GET /api/v2/catalog     ┌─────────────┐
│   Launch    │ ──────────────────────────▶ │   Backend   │
└─────────────┘                             └─────────────┘
       │                                           │
       │  (if network)                             │
       ▼                                           ▼
┌─────────────┐                             ┌─────────────┐
│ CatalogStore│ ◀─────────────────────────  │  JSON 15KB  │
│  (local)    │    Save to Documents/       └─────────────┘
└─────────────┘    catalog.json
       │
       │  (if offline, load cached)
       ▼
┌─────────────┐
│ BrowseView  │  All 735 songs in memory
└─────────────┘  Local search/filter
```

**Refresh strategy:**
- On launch: try network, fall back to cache
- Pull-to-refresh in BrowseView
- Store `Last-Modified` header, use `If-Modified-Since` to avoid re-downloading

### PDF Generation & Viewing

```
┌─────────────┐     POST /api/v2/generate    ┌─────────────┐
│  Tap Song   │ ──────────────────────────▶  │   Backend   │
└─────────────┘   {song, concert_key,        └─────────────┘
       │           transposition, clef}             │
       │                                           │
       │                                           ▼
       │                                    ┌─────────────┐
       │                                    │  S3 URL     │
       │                                    │  (15 min)   │
       │                                    └─────────────┘
       │                                           │
       ▼                                           ▼
┌─────────────┐                             ┌─────────────┐
│ PDFViewer   │ ◀────── Download PDF ────── │   S3 PDF    │
│  (PDFKit)   │                             └─────────────┘
└─────────────┘
```

**Request body:**
```json
{
  "song": "Blue Bossa",
  "concert_key": "c",
  "instrument_transposition": "Bb",
  "clef": "treble",
  "instrument_label": "Trumpet"
}
```

**Response:**
```json
{
  "url": "https://s3.../blue-bossa-c-Bb-treble.pdf?...",
  "cached": true,
  "crop": {"top": 50, "bottom": 30, "left": 20, "right": 20}
}
```

### Offline PDF Caching

```
┌─────────────────┐
│ SetlistDetail   │
│ "Download All"  │
└────────┬────────┘
         │
         │  For each song in setlist:
         ▼
┌─────────────────┐     POST /api/v2/generate
│   PDFCache      │ ─────────────────────────▶  Get S3 URL
└────────┬────────┘
         │
         │  Download PDF data
         ▼
┌─────────────────┐
│ Documents/PDFs/ │   {song-slug}-{key}-{trans}-{clef}.pdf
│   (on device)   │
└─────────────────┘
```

**Cache lookup:** Before calling API, check if PDF exists locally:
```swift
func getCachedPDF(song: String, key: String, transposition: String, clef: String) -> URL?
```

**Eviction:** Manual "Clear Downloads" in Settings, or LRU when storage exceeds threshold (e.g., 500MB).

### Setlists (iCloud)

```
┌─────────────┐                              ┌─────────────┐
│  Setlist    │ ◀──── CloudKit Sync ───────▶ │   iCloud    │
│  Changes    │       (automatic)            │   Private   │
└─────────────┘                              └─────────────┘
       │
       │  NSUbiquitousKeyValueStore (simple)
       │  or CKRecord (more control)
       ▼
┌─────────────────────────────────────┐
│ All user's Apple devices see same  │
│ setlists automatically             │
└─────────────────────────────────────┘
```

**Setlist model stored in iCloud:**
```swift
struct Setlist: Codable, Identifiable {
    let id: UUID
    var name: String
    var items: [SetlistItem]
    var createdAt: Date
}

struct SetlistItem: Codable, Identifiable {
    let id: UUID
    var songTitle: String
    var concertKey: String
    var position: Int
}
```

**Sync approach (simplest):** `NSUbiquitousKeyValueStore`
- 1MB limit, but setlists are tiny
- Automatic sync, no CloudKit dashboard setup
- Just read/write like UserDefaults

---

## Key Components

### APIClient.swift

```swift
final class APIClient: Sendable {
    static let shared = APIClient()
    private let baseURL = URL(string: "https://jazz-picker.fly.dev/api/v2")!

    func fetchCatalog() async throws -> [Song]
    func generatePDF(song: String, concertKey: String,
                     transposition: Transposition, clef: Clef,
                     instrumentLabel: String?) async throws -> GenerateResponse
}
```

Note: Changed from `actor` to `final class: Sendable` for Swift 6 compatibility (stateless, no actor isolation needed).

### CatalogStore.swift

```swift
@Observable
class CatalogStore {
    private(set) var songs: [Song] = []
    private(set) var isLoading = false

    func load() async                    // Load from cache or network
    func refresh() async                 // Force network refresh
    func search(_ query: String) -> [Song]  // Local filter
}
```

### PDFCache.swift

```swift
actor PDFCache {
    static let shared = PDFCache()

    func getCached(song: String, key: String, trans: String, clef: String) -> URL?
    func download(from url: URL, song: String, key: String, trans: String, clef: String) async throws -> URL
    func downloadSetlist(_ setlist: Setlist, instrument: Instrument) async throws
    func clearAll()
    var totalSize: Int64 { get }
}
```

### Instrument.swift

```swift
enum Instrument: String, CaseIterable, Codable, Identifiable, Sendable {
    case piano, guitar, trumpet, clarinet, tenorSax, sopranoSax, altoSax, bariSax, bass, trombone

    var label: String { ... }
    var transposition: Transposition { ... }  // .C, .Bb, .Eb
    var clef: Clef { ... }                    // .treble, .bass
}

enum Transposition: String, Codable, Sendable { case C, Bb, Eb }
enum Clef: String, Codable, Sendable { case treble, bass }
```

---

## Navigation Structure

```
TabView (BottomNav)
├── Browse (magnifyingglass)
│   └── BrowseView
│       └── NavigationStack
│           ├── Song list (root)
│           └── PDFViewerView (push)
│
├── Spin (custom center button)
│   └── Action: pick random song → present PDFViewerView
│
├── Setlists (music.note.list)
│   └── SetlistListView
│       └── NavigationStack
│           ├── Setlist list (root)
│           ├── SetlistDetailView (push)
│           │   └── PDFViewerView (push)
│           └── SetlistEditView (sheet)
│
└── Settings (gear)
    └── SettingsView
        ├── Instrument picker
        ├── Clear downloads
        └── About
```

---

## PDF Navigation & Gestures (Implemented)

### Swipe Behavior

One unified gesture system - swipes do the "logical next thing" based on context:

| Current State | Swipe Left | Swipe Right | Swipe Down |
|---------------|------------|-------------|------------|
| Page 1 of 2 | Previous song | Page 2 | Close |
| Page 2 of 2 | Page 1 | Next song | Close |
| Single page | Previous song | Next song | Close |

**Song transitions:** Animated with `withAnimation(.easeInOut)`, PDF viewer stays fullscreen.

**At list boundaries:** Haptic feedback (`UINotificationFeedbackGenerator.warning`), no wrap-around.

### Navigation Context

`PDFNavigationContext` enum in `Models/PDFNavigationContext.swift`:

```swift
enum PDFNavigationContext {
    case browse(songs: [Song], currentIndex: Int)
    // Swipe navigates through filtered song list

    case setlist(items: [SetlistItem], currentIndex: Int)
    // Swipe navigates through setlist order (Phase 2)

    case spin(randomSongProvider: () -> Song?)
    // Swipe left triggers another random song

    case single
    // No navigation (deep link, etc.)

    // Helper methods
    var canGoNext: Bool
    var canGoPrevious: Bool
    func nextSong() -> (song: Song, concertKey: String, newContext: PDFNavigationContext)?
    func previousSong() -> (song: Song, concertKey: String, newContext: PDFNavigationContext)?
}
```

### Page Detection (PDFKitView Coordinator)

```swift
class Coordinator: NSObject {
    func setupPageChangeObserver(for pdfView: PDFView, document: PDFDocument) {
        NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { [weak self] _ in
            self?.reportCurrentPage(pdfView: pdfView, document: document)
        }
    }
}
```

Callback reports `(currentPageIndex, totalPages)` to parent view for boundary detection.

---

## Transposition Data Model

### The Two Transpositions

When generating a PDF, two transpositions may occur:

1. **Song transposition** - Moving from the song's original key to a performance key
   - Example: "Autumn Leaves" from G to D (for a singer)
   - Stored in `SetlistItem.concertKey`

2. **Instrument transposition** - Adjusting notation for the player's instrument
   - Example: Concert D → Written E (for Bb trumpet)
   - Derived from user's instrument setting

Both happen in LilyPond at PDF generation time.

### Data Storage

**Catalog (backend SQLite):**
```sql
songs:
  title TEXT PRIMARY KEY
  default_key TEXT        -- Original concert key ("g")
  low_note_midi INTEGER
  high_note_midi INTEGER
```

**Setlist (iCloud, shared across band members):**
```swift
struct Setlist: Codable, Identifiable {
    let id: UUID
    var name: String
    var items: [SetlistItem]
    var createdAt: Date
}

struct SetlistItem: Codable, Identifiable {
    let id: UUID
    var songTitle: String
    var concertKey: String   // Performance key, may differ from default
    var position: Int
}
```

**User Settings (UserDefaults, per device):**
```swift
// Each user's instrument determines their PDF rendering
instrument: Instrument  // e.g., .trumpet → "Bb", "treble"
```

### API Parameters

```
POST /api/v2/generate
{
  "song": "Autumn Leaves",
  "concert_key": "d",                // From setlist or song.defaultKey
  "instrument_transposition": "Bb",  // From user's instrument (C, Bb, or Eb)
  "clef": "treble",
  "instrument_label": "Trumpet"      // For PDF subtitle
}
```

**Parameter naming:**
- `concert_key` - The key the band plays in (absolute)
- `instrument_transposition` - The user's instrument category (C, Bb, Eb)
- `clef` - Treble or bass
- `instrument_label` - Human-readable name for PDF display

### Band Sharing Example

Setlist "Friday Gig" stored in iCloud:
```json
{
  "name": "Friday Gig",
  "items": [
    { "songTitle": "Autumn Leaves", "concertKey": "d", "position": 0 }
  ]
}
```

Each band member generates their own PDF:

| Player | Instrument | API Request | PDF Shows |
|--------|------------|-------------|-----------|
| Piano | C | `concert_key=d, instrument_transposition=C` | D |
| Trumpet | Bb | `concert_key=d, instrument_transposition=Bb` | E |
| Alto Sax | Eb | `concert_key=d, instrument_transposition=Eb` | B |

Same setlist data → different PDFs per user's instrument.

---

## Implementation Order

### Phase 1: Core Browsing (MVP)
1. Project setup, folder structure
2. `Song` model + `APIClient.fetchCatalog()`
3. `CatalogStore` with local caching
4. `BrowseView` with search
5. `PDFViewerView` (port existing NativePDFViewController)
6. `Instrument` model + Settings storage (UserDefaults)
7. Tab navigation shell

**Result:** Can browse songs, pick instrument, view PDFs.

### Phase 2: Setlists
1. `Setlist` model
2. iCloud sync with `NSUbiquitousKeyValueStore`
3. `SetlistListView` (list, create, delete)
4. `SetlistDetailView` (perform mode)
5. `SetlistEditView` (reorder, add, remove)
6. Swipe between songs in PDF viewer

**Result:** Full setlist management synced across devices.

### Phase 3: Offline & Polish
1. `PDFCache` service
2. "Download for Offline" button on setlist
3. Spin button with animation
4. App icon, launch screen

**Result:** Gig-ready iPad app that works offline.

### Phase 4: Mac Support
1. Add macOS target
2. Sidebar navigation for Mac
3. Keyboard shortcuts, menu bar

**Result:** Native Mac app from same codebase.

### Phase 5: Auth & Sharing (Future)
1. Sign in with Apple
2. Server-side setlist backup
3. Shareable setlists

---

## API Reference

### GET /api/v2/catalog

Returns full song catalog.

**Response:**
```json
{
  "songs": [
    {
      "title": "502 Blues",
      "default_key": "a",
      "low_note_midi": 55,
      "high_note_midi": 79
    }
  ],
  "count": 735
}
```

### GET /api/v2/songs/:title/cached

Returns cached concert keys for a song + user's instrument transposition.

**Query params:** `instrument_transposition=Bb&clef=treble`

**Response:**
```json
{
  "default_key": "a",
  "cached_keys": ["a", "g", "bf"]
}
```

### POST /api/v2/generate

Generate or retrieve cached PDF.

**Request:**
```json
{
  "song": "502 Blues",
  "concert_key": "a",
  "instrument_transposition": "Bb",
  "clef": "treble",
  "instrument_label": "Trumpet"
}
```

**Response:**
```json
{
  "url": "https://jazz-picker-pdfs.s3.amazonaws.com/...",
  "cached": true,
  "generation_time_ms": 0,
  "crop": {
    "top": 47.5,
    "bottom": 28.0,
    "left": 18.0,
    "right": 18.0
  }
}
```

---

## Mac Support (Future)

**Approach:** SwiftUI Multiplatform (native Mac binary), NOT Mac Catalyst.

When ready to add Mac:
1. Add macOS target to existing project
2. 95% of SwiftUI code shared
3. Platform-specific UI where needed:

```swift
#if os(iOS)
    TabView { ... }  // Bottom tabs on iPad
#else
    NavigationSplitView { ... }  // Sidebar on Mac
#endif
```

**Mac-specific considerations:**
- Sidebar navigation instead of bottom tabs
- Keyboard shortcuts (already natural with SwiftUI)
- Window resizing (PDFView handles this well)
- Menu bar customization (optional)

**Not using Catalyst** because true SwiftUI multiplatform gives a more native Mac experience.

---

_Last updated: 2025-12-04_
