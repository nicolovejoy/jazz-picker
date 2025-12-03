# Session Handoff - Dec 2, 2025

## Just Completed
- **Spin** - Roulette wheel icon in nav bar, one-tap action (not a page)
  - Tap icon → wheel animates → random song opens
  - Closes to Browse context (not a spin page)
- **PDF transition overlay** - Loading spinner when swiping between songs (no flash to browse)
- **PDF viewer race condition fix** - Added key prop to Document component
- Consolidated "Spin the Dial" / "Roll the Dice" → unified "Spin" metaphor

## Current Stack
| Component | Location |
|-----------|----------|
| Web | jazzpicker.pianohouseproject.org (Vercel) |
| iOS | TestFlight (Jazz Picker) |
| Backend | jazz-picker.fly.dev (Fly.io) |
| Auth/DB | Supabase |
| PDFs | AWS S3 |

## TestFlight Deploy
```bash
cd frontend && npm run build && npx cap sync ios
open ios/App/App.xcworkspace
# Xcode: "Any iOS Device (arm64)" → Product → Archive → Distribute
```

## Key Components Changed
- `RouletteIcon.tsx` - SVG roulette wheel with spin animation
- `BottomNav.tsx` - Spin triggers action directly (onSpin callback)
- `PDFViewer.tsx` - Transition overlay, race condition fix
- `App.tsx` - isSpinning/isPdfTransitioning state management

## Clear S3 Cache
After deploying crop detection, clear the S3 cache to regenerate PDFs with crop metadata:
```bash
aws s3 rm s3://jazz-picker-pdfs/generated/ --recursive
```

## Next Up
1. Setlist Edit mode (drag-drop, reorder, key +/-)
2. Offline PDF caching
3. Pre-cache setlist PDFs on app load
4. Home page with one-click setlist access
