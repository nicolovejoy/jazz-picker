# PDF Viewing Vision

**Goal:** Immersive, distraction-free sheet music viewing like forScore.

## Requirements

1. **Full bleed** - White PDF extends edge-to-edge, minimal chrome
2. **No status bar** - Time/battery/wifi completely hidden
3. **Landscape mode** - Two pages side-by-side
4. **Portrait mode** - Single page, fills screen
5. **Controls auto-hide** - Appear on tap, disappear after 2 seconds
6. **Smart cropping** - Automatically detect and trim whitespace margins

## Implementation Status

### Completed
- Native iOS viewer with PDFKit
- Status bar + home indicator hidden
- Two-page landscape (`.twoUpContinuous`)
- Single-page portrait (`.singlePageContinuous`)
- Auto-hiding controls (2s timeout)
- Swipe down to close
- Swipe gestures for setlist navigation
- Auto-crop detection via PyMuPDF (backend)
- Crop bounds stored in S3 metadata
- iOS applies cropBox to PDF pages

### How Crop Detection Works
1. Backend generates PDF via LilyPond
2. PyMuPDF renders at low DPI, scans for non-white pixels
3. Calculates trim amounts (top, bottom, left, right) in PDF points
4. Stored in S3 object metadata, returned in API response
5. iOS applies cropBox before display, removing excess whitespace
